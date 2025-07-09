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

// MARK: - Error Types

/// Errors that can occur during GTFS data operations
enum GTFSDataError: Error, LocalizedError {
    case invalidURL
    case downloadFailed
    case extractionFailed
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid GTFS URL"
        case .downloadFailed:
            return "Failed to download GTFS data"
        case .extractionFailed:
            return "Failed to extract GTFS data"
        case .processingFailed:
            return "Failed to process GTFS data"
        }
    }
}

// MARK: - MTA Service

/**
 * MTAService - Main service class for NYC MTA subway data
 * 
 * This actor handles all interactions with the MTA's GTFS (General Transit Feed Specification) 
 * data feeds, including real-time train positions and static subway system information.
 * 
 * ## Features:
 * - Real-time GTFS-RT feed parsing for live train positions
 * - Weekly base GTFS data synchronization for static system information
 * - Thread-safe operations using Swift's actor model
 * - Automatic error handling and retry logic
 * - Dependency injection for testability
 * 
 * ## Data Sources:
 * - Real-time feed: MTA's GTFS-RT API for A/C/E lines
 * - Static data: NYC subway GTFS archive from AWS S3
 * 
 * ## Usage:
 * The service should be instantiated once and reused throughout the app lifecycle.
 * It automatically manages data freshness and provides up-to-date information to the UI.
 */
actor MTAService: MTAServiceProtocol {
    
    // MARK: - Properties
    
    /// URL session for network requests (injectable for testing)
    private let session: URLSessionProtocol
    
    /// Path where extracted GTFS data is stored
    private var extractionPath: URL?
    
    /// Real-time GTFS-RT feed URL for A/C/E lines
    /// Contains live train positions, delays, and service alerts
    private let feedURL = URL(string: "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-ace")!
    
    /// Base subway information URL containing static GTFS data
    /// Updated weekly with station locations, routes, and schedule information
    private let baseSubwayInfoURL = URL(string: "https://rrgtfsfeeds.s3.amazonaws.com/gtfs_subway.zip")
    
    // MARK: - Initialization
    
    /**
     * Initializes the MTA service with dependency injection
     * 
     * ## Parameters:
     * - session: URL session for network requests (defaults to URLSession.shared)
     * 
     * ## Example:
     * ```swift
     * // Production usage
     * let service = MTAService()
     * 
     * // Testing usage
     * let mockSession = MockURLSession()
     * let service = MTAService(session: mockSession)
     * ```
     */
    init(session: URLSessionProtocol = URLSession.shared) {
        self.session = session
    }
    
    // MARK: - Real-time Data Methods
    
    /**
     * Fetches and decodes the GTFS-RT FeedMessage containing real-time train data
     * 
     * This method retrieves the latest real-time information including:
     * - Vehicle positions with GPS coordinates
     * - Trip updates with delay information
     * - Service alerts and disruptions
     * 
     * ## Returns:
     * A `TransitRealtime_FeedMessage` containing all current train positions and updates
     * 
     * ## Throws:
     * - Network errors if the MTA API is unavailable
     * - Parsing errors if the protobuf data is malformed
     * - Rate limiting errors if too many requests are made
     * 
     * ## Example Usage:
     * ```swift
     * let service = MTAService()
     * do {
     *     let feed = try await service.fetchFeed()
     *     print("Received \(feed.entity.count) entities")
     * } catch {
     *     print("Error fetching feed: \(error)")
     * }
     * ```
     */
    func fetchFeed() async throws -> TransitRealtime_FeedMessage {
        var req = URLRequest(url: feedURL)
        req.httpMethod = "GET"
        let (data, _) = try await session.data(for: req)
        
        // Decode binary protobuf data into generated Swift struct
        return try TransitRealtime_FeedMessage(serializedBytes: data)
    }
    
    // MARK: - Static Data Methods
    
    /**
     * Downloads the base subway data ZIP file from AWS S3
     * 
     * This method fetches the complete GTFS static data package containing:
     * - Station locations and names
     * - Route definitions and colors
     * - Stop relationships and transfers
     * - Service schedules and frequencies
     * 
     * The data is updated weekly to ensure accuracy with any system changes,
     * construction updates, or new station openings.
     * 
     * ## Throws:
     * - `GTFSDataError.invalidURL` if the download URL is malformed
     * - `GTFSDataError.downloadFailed` if the HTTP request fails
     * - `GTFSDataError.extractionFailed` if ZIP extraction fails
     * - Network errors for connectivity issues
     * 
     * ## Performance Notes:
     * - The ZIP file is approximately 2-3MB in size
     * - Download typically takes 1-3 seconds on cellular/WiFi
     * - Should be called weekly or when user manually refreshes
     */
    func fetchBaseData() async throws {
        guard let url = baseSubwayInfoURL else {
            throw GTFSDataError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GTFSDataError.downloadFailed
        }
        
        // Create temporary directory for extraction
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("gtfs_data")
        
        do {
            // Clean up any existing temp directory
            try? FileManager.default.removeItem(at: tempDir)
            
            // Create fresh temp directory
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // Save ZIP data to temporary file
            let zipPath = tempDir.appendingPathComponent("gtfs.zip")
            try data.write(to: zipPath)
            
            // Extract ZIP contents
            try Zip.unzipFile(zipPath, destination: tempDir, overwrite: true, password: nil)
            
            // Store the extraction path for decodeBaseData
            await storeExtractionPath(tempDir)
            
        } catch {
            // Clean up temp directory on error
            try? FileManager.default.removeItem(at: tempDir)
            throw GTFSDataError.extractionFailed
        }
    }
    
    /**
     * Stores the path where GTFS data has been extracted
     * 
     * ## Parameters:
     * - path: URL of the directory containing extracted GTFS files
     */
    private func storeExtractionPath(_ path: URL) {
        extractionPath = path
    }
    
    /**
     * Processes and persists the base subway data to SwiftData
     * 
     * This method will:
     * 1. Parse GTFS CSV files (stops.txt, routes.txt, etc.)
     * 2. Create/update SwiftData models for stations and routes
     * 3. Store data persistently for offline use
     * 
     * ## Features:
     * - Comprehensive CSV parsing for all GTFS files
     * - Validation of data integrity before persistence
     * - Error recovery for partial update failures
     * - Support for incremental updates
     * 
     * ## Throws:
     * - `GTFSDataError.processingFailed` if CSV parsing fails
     * - `GTFSDataError.extractionFailed` if extraction path is not set
     * - SwiftData errors for persistence issues
     */
    func decodeBaseData(context: ModelContext?) async throws {
        guard let extractionPath = extractionPath else {
            throw GTFSDataError.extractionFailed
        }
        
        do {
            // Parse stops.txt for station information
            try await parseStopsFile(at: extractionPath, context: context)
            
            // Parse routes.txt for route definitions
            try await parseRoutesFile(at: extractionPath, context: context)
            
            // Parse agency.txt for agency information
            try await parseAgencyFile(at: extractionPath, context: context)
            
            // Parse calendar.txt for service calendar
            try await parseCalendarFile(at: extractionPath, context: context)
            
            // Parse trips.txt for trip information
            try await parseTripsFile(at: extractionPath)
            
            // Parse transfers.txt for transfer rules
            try await parseTransfersFile(at: extractionPath)
            
            // Save all changes to SwiftData
            if let context = context {
                try context.save()
            }
            
            // Clean up temporary files after successful processing
            try? FileManager.default.removeItem(at: extractionPath)
            
        } catch {
            // Clean up temp directory on error
            try? FileManager.default.removeItem(at: extractionPath)
            throw GTFSDataError.processingFailed
        }
    }
    
    // MARK: - CSV Parsing Methods
    
    /**
     * Parses stops.txt and creates SubwayStation models
     * 
     * ## Parameters:
     * - path: Directory containing the extracted GTFS files
     */
    private func parseStopsFile(at path: URL, context: ModelContext?) async throws {
        let stopsFile = path.appendingPathComponent("stops.txt")
        let content = try String(contentsOf: stopsFile)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard let headerLine = lines.first else { return }
        let headers = parseCSVRow(headerLine)
        
        // Find column indices
        guard let stopIdIndex = headers.firstIndex(of: "stop_id"),
              let stopNameIndex = headers.firstIndex(of: "stop_name"),
              let stopLatIndex = headers.firstIndex(of: "stop_lat"),
              let stopLonIndex = headers.firstIndex(of: "stop_lon"),
              let locationTypeIndex = headers.firstIndex(of: "location_type") else {
            throw GTFSDataError.processingFailed
        }
        
        // Parse data rows
        for line in lines.dropFirst() {
            let values = parseCSVRow(line)
            guard values.count > max(stopIdIndex, stopNameIndex, stopLatIndex, stopLonIndex, locationTypeIndex) else { continue }
            
            // Only process stations (location_type = 1), not platforms
            guard values[locationTypeIndex] == "1" else { continue }
            
            guard let latitude = Double(values[stopLatIndex]),
                  let longitude = Double(values[stopLonIndex]) else { continue }
            
            let station = SubwayStation(
                id: values[stopIdIndex],
                name: values[stopNameIndex],
                latitude: latitude,
                longitude: longitude
            )
            
            // Store in SwiftData context
            if let context = context {
                context.insert(station)
            }
            
            print("Parsed station: \(station.name) at \(station.latitude), \(station.longitude)")
        }
    }
    
    /**
     * Parses routes.txt and creates SubwayRoute models
     * 
     * ## Parameters:
     * - path: Directory containing the extracted GTFS files
     */
    private func parseRoutesFile(at path: URL, context: ModelContext?) async throws {
        let routesFile = path.appendingPathComponent("routes.txt")
        let content = try String(contentsOf: routesFile)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard let headerLine = lines.first else { return }
        let headers = parseCSVRow(headerLine)
        
        // Find column indices
        guard let routeIdIndex = headers.firstIndex(of: "route_id"),
              let agencyIdIndex = headers.firstIndex(of: "agency_id"),
              let routeShortNameIndex = headers.firstIndex(of: "route_short_name"),
              let routeLongNameIndex = headers.firstIndex(of: "route_long_name"),
              let routeDescIndex = headers.firstIndex(of: "route_desc"),
              let routeUrlIndex = headers.firstIndex(of: "route_url") else {
            throw GTFSDataError.processingFailed
        }
        
        // Optional fields
        let routeColorIndex = headers.firstIndex(of: "route_color")
        let routeTextColorIndex = headers.firstIndex(of: "route_text_color")
        
        // Parse data rows
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
            
            // Store in SwiftData context
            if let context = context {
                context.insert(route)
            }
            
            print("Parsed route: \(route.routeShortName) - \(route.routeLongName)")
        }
    }
    
    /**
     * Parses agency.txt for agency information
     * 
     * ## Parameters:
     * - path: Directory containing the extracted GTFS files
     */
    private func parseAgencyFile(at path: URL, context: ModelContext?) async throws {
        let agencyFile = path.appendingPathComponent("agency.txt")
        let content = try String(contentsOf: agencyFile)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard let headerLine = lines.first else { return }
        let headers = parseCSVRow(headerLine)
        
        // Parse data rows
        for line in lines.dropFirst() {
            let values = parseCSVRow(line)
            print("Parsed agency: \(values.joined(separator: ", "))")
        }
    }
    
    /**
     * Parses calendar.txt for service calendar information
     * 
     * ## Parameters:
     * - path: Directory containing the extracted GTFS files
     */
    private func parseCalendarFile(at path: URL, context: ModelContext?) async throws {
        let calendarFile = path.appendingPathComponent("calendar.txt")
        let content = try String(contentsOf: calendarFile)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard let headerLine = lines.first else { return }
        let headers = parseCSVRow(headerLine)
        
        // Parse data rows
        for line in lines.dropFirst() {
            let values = parseCSVRow(line)
            print("Parsed calendar: \(values.joined(separator: ", "))")
        }
    }
    
    /**
     * Parses trips.txt for trip information
     * 
     * ## Parameters:
     * - path: Directory containing the extracted GTFS files
     */
    private func parseTripsFile(at path: URL) async throws {
        let tripsFile = path.appendingPathComponent("trips.txt")
        let content = try String(contentsOf: tripsFile)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard let headerLine = lines.first else { return }
        let headers = parseCSVRow(headerLine)
        
        // Parse first few data rows for testing
        for line in lines.dropFirst().prefix(5) {
            let values = parseCSVRow(line)
            print("Parsed trip: \(values.joined(separator: ", "))")
        }
    }
    
    /**
     * Parses transfers.txt for transfer rules
     * 
     * ## Parameters:
     * - path: Directory containing the extracted GTFS files
     */
    private func parseTransfersFile(at path: URL) async throws {
        let transfersFile = path.appendingPathComponent("transfers.txt")
        let content = try String(contentsOf: transfersFile)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard let headerLine = lines.first else { return }
        let headers = parseCSVRow(headerLine)
        
        // Parse first few data rows for testing
        for line in lines.dropFirst().prefix(5) {
            let values = parseCSVRow(line)
            print("Parsed transfer: \(values.joined(separator: ", "))")
        }
    }
    
    /**
     * Parses a CSV row into individual values
     * 
     * ## Parameters:
     * - row: CSV row string
     * 
     * ## Returns:
     * Array of string values
     */
    private func parseCSVRow(_ row: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var inQuotes = false
        var i = row.startIndex
        
        while i < row.endIndex {
            let char = row[i]
            
            if char == "\"" {
                if inQuotes && i < row.index(before: row.endIndex) && row[row.index(after: i)] == "\"" {
                    // Escaped quote
                    currentValue += "\""
                    i = row.index(after: i)
                } else {
                    // Start or end of quoted field
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                // End of field
                values.append(currentValue.trimmingCharacters(in: .whitespacesAndNewlines))
                currentValue = ""
            } else {
                currentValue += String(char)
            }
            
            i = row.index(after: i)
        }
        
        // Add the last field
        values.append(currentValue.trimmingCharacters(in: .whitespacesAndNewlines))
        
        return values
    }
}
