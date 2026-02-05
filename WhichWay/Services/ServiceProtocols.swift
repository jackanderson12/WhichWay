//
//  ServiceProtocols.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/9/25.
//

import Foundation
import SwiftData

// MARK: - Service Protocols

protocol MTAServiceProtocol: Sendable {
    func fetchFeed() async throws -> TransitRealtime_FeedMessage
    func fetchAllFeeds() async throws -> [TransitRealtime_FeedMessage]
    func getCachedFeeds() async -> [TransitRealtime_FeedMessage]
    func fetchBaseData() async throws
    func decodeBaseData(context: ModelContext?) async throws
    func getChildStopIds(for stationId: String) async -> [String]
    func getRoutesForStation(_ stationId: String) async -> [String]
    func getChildToParentMap() async -> [String: String]
}

protocol GTFSDataProcessorProtocol {
    func processTrainPositions(from feed: TransitRealtime_FeedMessage) -> [TrainPosition]
    func processAllFeeds(_ feeds: [TransitRealtime_FeedMessage]) -> [TrainPosition]
    func extractStopInfos(from tripUpdate: TransitRealtime_TripUpdate) -> [StopInfo]
    func createTrainPosition(
        tripId: String,
        vehicle: TransitRealtime_VehiclePosition?,
        tripUpdate: TransitRealtime_TripUpdate?
    ) -> TrainPosition?
    func extractArrivals(
        for stationId: String,
        childStopIds: [String],
        from feeds: [TransitRealtime_FeedMessage],
        routeColors: [String: (color: String, textColor: String)]
    ) -> [StationArrival]
}

protocol StationNameResolverProtocol {
    func resolveName(for stopId: String) -> String
    func resolveCoordinate(for stopId: String) -> (latitude: Double, longitude: Double)?
}

protocol URLSessionProtocol {
    func data(from url: URL) async throws -> (Data, URLResponse)
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// MARK: - URLSession Protocol Conformance

extension URLSession: URLSessionProtocol {}
