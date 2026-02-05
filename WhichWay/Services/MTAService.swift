//
//  MTAService.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/15/25.
//

import Foundation
import SwiftProtobuf
import Zip
import SwiftData
import CoreLocation

// MARK: - Error Types

enum GTFSDataError: Error, LocalizedError {
    case invalidURL
    case downloadFailed
    case extractionFailed
    case processingFailed

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid GTFS URL"
        case .downloadFailed: return "Failed to download GTFS data"
        case .extractionFailed: return "Failed to extract GTFS data"
        case .processingFailed: return "Failed to process GTFS data"
        }
    }
}

// MARK: - MTA Service

actor MTAService: MTAServiceProtocol {

    // MARK: - Properties

    private let session: URLSessionProtocol
    private var extractionPath: URL?

    /// All GTFS-RT feed URLs for NYC subway line groups
    static let feedURLs: [URL] = [
        URL(string: "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs")!,        // 1,2,3,4,5,6,7,S
        URL(string: "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-ace")!,     // A,C,E
        URL(string: "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-bdfm")!,    // B,D,F,M
        URL(string: "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-g")!,       // G
        URL(string: "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-jz")!,      // J,Z
        URL(string: "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-l")!,       // L
        URL(string: "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-nqrw")!,    // N,Q,R,W
        URL(string: "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-si")!,      // SIR
    ]

    private let baseSubwayInfoURL = URL(string: "https://rrgtfsfeeds.s3.amazonaws.com/gtfs_subway.zip")

    /// Cached feeds for arrival lookups without re-fetching
    private var cachedFeeds: [TransitRealtime_FeedMessage] = []

    /// Maps child stop ID (e.g., "127N") → parent station ID (e.g., "127")
    private var childToParentMap: [String: String] = [:]

    /// Maps parent station ID → set of route IDs serving it
    private var stationRouteMap: [String: Set<String>] = [:]

    /// Maps trip ID → route ID (from trips.txt)
    private var tripRouteMap: [String: String] = [:]

    /// Maps shape ID → route ID (from trips.txt)
    private var shapeRouteMap: [String: String] = [:]

    // MARK: - Initialization

    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }

    // MARK: - Real-time Feed Methods

    func fetchFeed() async throws -> TransitRealtime_FeedMessage {
        let url = Self.feedURLs[0]
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let (data, _) = try await session.data(for: req)
        return try TransitRealtime_FeedMessage(serializedBytes: data)
    }

    func fetchAllFeeds() async throws -> [TransitRealtime_FeedMessage] {
        let feeds = try await withThrowingTaskGroup(of: TransitRealtime_FeedMessage?.self, returning: [TransitRealtime_FeedMessage].self) { group in
            for url in Self.feedURLs {
                group.addTask { [session] in
                    do {
                        var req = URLRequest(url: url)
                        req.httpMethod = "GET"
                        let (data, _) = try await session.data(for: req)
                        return try TransitRealtime_FeedMessage(serializedBytes: data)
                    } catch {
                        print("Failed to fetch feed \(url.lastPathComponent): \(error)")
                        return nil
                    }
                }
            }

            var results: [TransitRealtime_FeedMessage] = []
            for try await feed in group {
                if let feed = feed {
                    results.append(feed)
                }
            }
            return results
        }

        cachedFeeds = feeds
        print("Fetched \(feeds.count) feeds with \(feeds.reduce(0) { $0 + $1.entity.count }) total entities")
        return feeds
    }

    func getCachedFeeds() -> [TransitRealtime_FeedMessage] {
        return cachedFeeds
    }

    func getChildStopIds(for stationId: String) -> [String] {
        return childToParentMap.compactMap { (childId, parentId) in
            parentId == stationId ? childId : nil
        }
    }

    func getRoutesForStation(_ stationId: String) -> [String] {
        return Array(stationRouteMap[stationId] ?? [])
    }

    func getChildToParentMap() -> [String: String] {
        return childToParentMap
    }

    // MARK: - Static Data Methods

    func fetchBaseData() async throws {
        guard let url = baseSubwayInfoURL else {
            throw GTFSDataError.invalidURL
        }

        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GTFSDataError.downloadFailed
        }

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("gtfs_data")

        do {
            try? FileManager.default.removeItem(at: tempDir)
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

            let zipPath = tempDir.appendingPathComponent("gtfs.zip")
            try data.write(to: zipPath)
            try Zip.unzipFile(zipPath, destination: tempDir, overwrite: true, password: nil)

            extractionPath = tempDir
        } catch {
            try? FileManager.default.removeItem(at: tempDir)
            throw GTFSDataError.extractionFailed
        }
    }

    func decodeBaseData(context: ModelContext?) async throws {
        guard let extractionPath = extractionPath else {
            throw GTFSDataError.extractionFailed
        }

        do {
            // Parse stops.txt — builds stations AND child stop mapping
            try await parseStopsFile(at: extractionPath, context: context)

            // Parse routes.txt
            try await parseRoutesFile(at: extractionPath, context: context)

            // Parse trips.txt — builds tripId→routeId and shapeId→routeId maps
            try await parseTripsFile(at: extractionPath)

            // Parse stop_times.txt — builds stationId→routeIds mapping
            try await parseStopTimesFile(at: extractionPath)

            // Parse shapes.txt — builds route polylines
            try await parseShapesFile(at: extractionPath, context: context)

            // Update station models with child stop IDs and route IDs
            try await updateStationsWithMappings(context: context)

            if let context = context {
                try context.save()
            }

            try? FileManager.default.removeItem(at: extractionPath)

        } catch {
            try? FileManager.default.removeItem(at: extractionPath)
            throw GTFSDataError.processingFailed
        }
    }

    // MARK: - CSV Parsing Methods

    private func parseStopsFile(at path: URL, context: ModelContext?) async throws {
        let stopsFile = path.appendingPathComponent("stops.txt")
        let content = try String(contentsOf: stopsFile, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard let headerLine = lines.first else { return }
        let headers = parseCSVRow(headerLine)

        guard let stopIdIndex = headers.firstIndex(of: "stop_id"),
              let stopNameIndex = headers.firstIndex(of: "stop_name"),
              let stopLatIndex = headers.firstIndex(of: "stop_lat"),
              let stopLonIndex = headers.firstIndex(of: "stop_lon"),
              let locationTypeIndex = headers.firstIndex(of: "location_type") else {
            throw GTFSDataError.processingFailed
        }

        let parentStationIndex = headers.firstIndex(of: "parent_station")

        for line in lines.dropFirst() {
            let values = parseCSVRow(line)
            guard values.count > max(stopIdIndex, stopNameIndex, stopLatIndex, stopLonIndex, locationTypeIndex) else { continue }

            let stopId = values[stopIdIndex]
            let locationType = values[locationTypeIndex]

            if locationType == "1" {
                // Parent station
                guard let latitude = Double(values[stopLatIndex]),
                      let longitude = Double(values[stopLonIndex]) else { continue }

                let station = SubwayStation(
                    id: stopId,
                    name: values[stopNameIndex],
                    latitude: latitude,
                    longitude: longitude
                )

                if let context = context {
                    context.insert(station)
                }
            } else {
                // Child stop (platform) — map to parent
                if let parentIdx = parentStationIndex, values.count > parentIdx {
                    let parentId = values[parentIdx]
                    if !parentId.isEmpty {
                        childToParentMap[stopId] = parentId
                    }
                }
            }
        }

        print("Parsed \(childToParentMap.count) child stop → parent station mappings")
    }

    private func parseRoutesFile(at path: URL, context: ModelContext?) async throws {
        let routesFile = path.appendingPathComponent("routes.txt")
        let content = try String(contentsOf: routesFile, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard let headerLine = lines.first else { return }
        let headers = parseCSVRow(headerLine)

        guard let routeIdIndex = headers.firstIndex(of: "route_id"),
              let agencyIdIndex = headers.firstIndex(of: "agency_id"),
              let routeShortNameIndex = headers.firstIndex(of: "route_short_name"),
              let routeLongNameIndex = headers.firstIndex(of: "route_long_name"),
              let routeDescIndex = headers.firstIndex(of: "route_desc"),
              let routeUrlIndex = headers.firstIndex(of: "route_url") else {
            throw GTFSDataError.processingFailed
        }

        let routeColorIndex = headers.firstIndex(of: "route_color")
        let routeTextColorIndex = headers.firstIndex(of: "route_text_color")

        for line in lines.dropFirst() {
            let values = parseCSVRow(line)
            guard values.count > max(routeIdIndex, agencyIdIndex, routeShortNameIndex, routeLongNameIndex, routeDescIndex, routeUrlIndex) else { continue }

            let routeColor = routeColorIndex != nil && values.count > routeColorIndex! ? values[routeColorIndex!] : nil
            let routeTextColor = routeTextColorIndex != nil && values.count > routeTextColorIndex! ? values[routeTextColorIndex!] : nil

            let route = SubwayRoute(
                routeId: values[routeIdIndex],
                agencyId: values[agencyIdIndex],
                routeShortName: values[routeShortNameIndex],
                routeLongName: values[routeLongNameIndex],
                routeDescription: values[routeDescIndex],
                routeUrl: values[routeUrlIndex],
                routeColor: routeColor?.isEmpty == false ? routeColor : nil,
                routeTextColor: routeTextColor?.isEmpty == false ? routeTextColor : nil
            )

            if let context = context {
                context.insert(route)
            }
        }
    }

    private func parseTripsFile(at path: URL) async throws {
        let tripsFile = path.appendingPathComponent("trips.txt")
        let content = try String(contentsOf: tripsFile, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard let headerLine = lines.first else { return }
        let headers = parseCSVRow(headerLine)

        guard let tripIdIndex = headers.firstIndex(of: "trip_id"),
              let routeIdIndex = headers.firstIndex(of: "route_id") else {
            return
        }

        let shapeIdIndex = headers.firstIndex(of: "shape_id")

        for line in lines.dropFirst() {
            let values = parseCSVRow(line)
            guard values.count > max(tripIdIndex, routeIdIndex) else { continue }

            let tripId = values[tripIdIndex]
            let routeId = values[routeIdIndex]
            tripRouteMap[tripId] = routeId

            if let shapeIdx = shapeIdIndex, values.count > shapeIdx {
                let shapeId = values[shapeIdx]
                if !shapeId.isEmpty {
                    shapeRouteMap[shapeId] = routeId
                }
            }
        }

        print("Parsed \(tripRouteMap.count) trip→route mappings")
    }

    private func parseStopTimesFile(at path: URL) async throws {
        let stopTimesFile = path.appendingPathComponent("stop_times.txt")
        let content = try String(contentsOf: stopTimesFile, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard let headerLine = lines.first else { return }
        let headers = parseCSVRow(headerLine)

        guard let tripIdIndex = headers.firstIndex(of: "trip_id"),
              let stopIdIndex = headers.firstIndex(of: "stop_id") else {
            return
        }

        // Track unique (station, route) pairs to avoid redundant work
        var seenPairs: Set<String> = []

        for line in lines.dropFirst() {
            let values = parseCSVRow(line)
            guard values.count > max(tripIdIndex, stopIdIndex) else { continue }

            let tripId = values[tripIdIndex]
            let stopId = values[stopIdIndex]

            guard let routeId = tripRouteMap[tripId] else { continue }

            // Resolve to parent station
            let parentStationId = childToParentMap[stopId] ?? stopId

            let pairKey = "\(parentStationId):\(routeId)"
            guard !seenPairs.contains(pairKey) else { continue }
            seenPairs.insert(pairKey)

            stationRouteMap[parentStationId, default: []].insert(routeId)
        }

        print("Parsed station→route mappings for \(stationRouteMap.count) stations")
    }

    private func parseShapesFile(at path: URL, context: ModelContext?) async throws {
        let shapesFile = path.appendingPathComponent("shapes.txt")
        guard FileManager.default.fileExists(atPath: shapesFile.path) else { return }

        let content = try String(contentsOf: shapesFile, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard let headerLine = lines.first else { return }
        let headers = parseCSVRow(headerLine)

        guard let shapeIdIndex = headers.firstIndex(of: "shape_id"),
              let latIndex = headers.firstIndex(of: "shape_pt_lat"),
              let lonIndex = headers.firstIndex(of: "shape_pt_lon"),
              let seqIndex = headers.firstIndex(of: "shape_pt_sequence") else {
            return
        }

        // Group coordinates by shape ID, preserving sequence order
        var shapePoints: [String: [(seq: Int, lat: Double, lon: Double)]] = [:]

        for line in lines.dropFirst() {
            let values = parseCSVRow(line)
            guard values.count > max(shapeIdIndex, latIndex, lonIndex, seqIndex) else { continue }

            guard let lat = Double(values[latIndex]),
                  let lon = Double(values[lonIndex]),
                  let seq = Int(values[seqIndex]) else { continue }

            let shapeId = values[shapeIdIndex]
            shapePoints[shapeId, default: []].append((seq: seq, lat: lat, lon: lon))
        }

        // Deduplicate: only keep one shape per route (the first one encountered)
        var routeShapesSeen: Set<String> = []

        for (shapeId, points) in shapePoints {
            guard let routeId = shapeRouteMap[shapeId] else { continue }
            guard !routeShapesSeen.contains(routeId) else { continue }
            routeShapesSeen.insert(routeId)

            let sorted = points.sorted { $0.seq < $1.seq }
            let coordinates = sorted.map {
                CLLocationCoordinate2D(latitude: $0.lat, longitude: $0.lon)
            }

            let polyline = SubwayRoutePolyline(routeId: routeId, coordinates: coordinates)
            if let context = context {
                context.insert(polyline)
            }
        }

        print("Parsed \(routeShapesSeen.count) route polylines from shapes.txt")
    }

    private func updateStationsWithMappings(context: ModelContext?) async throws {
        guard let context = context else { return }

        let descriptor = FetchDescriptor<SubwayStation>()
        let stations = try context.fetch(descriptor)

        for station in stations {
            station.childStopIds = getChildStopIds(for: station.id)
            station.routeIds = Array(stationRouteMap[station.id] ?? []).sorted()
        }

        print("Updated \(stations.count) stations with child stop IDs and route mappings")
    }

    // MARK: - CSV Parser

    private func parseCSVRow(_ row: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var inQuotes = false
        var i = row.startIndex

        while i < row.endIndex {
            let char = row[i]

            if char == "\"" {
                if inQuotes && i < row.index(before: row.endIndex) && row[row.index(after: i)] == "\"" {
                    currentValue += "\""
                    i = row.index(after: i)
                } else {
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                values.append(currentValue.trimmingCharacters(in: .whitespacesAndNewlines))
                currentValue = ""
            } else {
                currentValue += String(char)
            }

            i = row.index(after: i)
        }

        values.append(currentValue.trimmingCharacters(in: .whitespacesAndNewlines))
        return values
    }
}
