//
//  MapViewModel.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/15/25.
//

import Foundation
import SwiftUI
import SwiftProtobuf
import MapKit
import Observation

@Observable
class MapViewModel {

    // MARK: - State

    var trainPositions: [TrainPosition] = []
    var stationArrivals: [StationArrival] = []
    var isLoading = false
    var error: Error?
    var selectedStation: SubwayStation?
    var isShowingStationDetail = false

    // MARK: - Dependencies

    private let mtaService: MTAServiceProtocol
    private let dataProcessor: GTFSDataProcessorProtocol
    let locationManager = LocationManager()

    /// Route color lookup: routeId -> (color hex, textColor hex)
    var routeColorMap: [String: (color: String, textColor: String)] = [:]

    private var refreshTask: Task<Void, Never>?

    // MARK: - Initialization

    init(
        mtaService: MTAServiceProtocol = MTAService(),
        dataProcessor: GTFSDataProcessorProtocol = GTFSDataProcessor()
    ) {
        self.mtaService = mtaService
        self.dataProcessor = dataProcessor
    }

    // MARK: - Feed Fetching

    @MainActor
    func startFeedRefreshLoop() {
        refreshTask?.cancel()
        refreshTask = Task {
            while !Task.isCancelled {
                await fetchAllTrainPositions()
                try? await Task.sleep(for: .seconds(30))
            }
        }
    }

    @MainActor
    func fetchAllTrainPositions() async {
        isLoading = true
        error = nil

        do {
            let feeds = try await mtaService.fetchAllFeeds()
            trainPositions = dataProcessor.processAllFeeds(feeds)
            print("Loaded \(trainPositions.count) train positions from \(feeds.count) feeds")
        } catch {
            print("Error fetching feeds: \(error)")
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Station Arrivals

    @MainActor
    func fetchArrivals(for station: SubwayStation) async {
        let feeds = await mtaService.getCachedFeeds()

        var childStopIds = station.childStopIds
        if childStopIds.isEmpty {
            childStopIds = [station.id, "\(station.id)N", "\(station.id)S"]
        }

        stationArrivals = dataProcessor.extractArrivals(
            for: station.id,
            childStopIds: childStopIds,
            from: feeds,
            routeColors: routeColorMap
        )

        print("Found \(stationArrivals.count) arrivals for \(station.name)")
    }

    @MainActor
    func selectStation(_ station: SubwayStation) {
        selectedStation = station
        isShowingStationDetail = true
        Task {
            await fetchArrivals(for: station)
        }
    }

    // MARK: - Location

    func requestLocationPermission() {
        locationManager.requestPermission()
    }

    func nearestStations(from stations: [SubwayStation], count: Int = 3) -> [SubwayStation] {
        guard let userLocation = locationManager.location else { return [] }
        return Array(
            stations
                .sorted { $0.distance(to: userLocation.coordinate) < $1.distance(to: userLocation.coordinate) }
                .prefix(count)
        )
    }

    // MARK: - Route Colors

    func buildRouteColorMap(from routes: [SubwayRoute]) {
        routeColorMap = [:]
        for route in routes {
            routeColorMap[route.routeId] = (
                color: route.routeColor ?? "808080",
                textColor: route.routeTextColor ?? "FFFFFF"
            )
        }
    }

    // MARK: - Cleanup

    func stopRefresh() {
        refreshTask?.cancel()
        refreshTask = nil
    }
}
