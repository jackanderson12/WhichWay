//
//  ServiceProtocols.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/9/25.
//

import Foundation
import SwiftData

// MARK: - Service Protocols

/**
 * Protocol for MTA data service operations
 * 
 * This protocol defines the interface for fetching and processing MTA data,
 * enabling dependency injection and making the service easily testable.
 */
protocol MTAServiceProtocol {
    /// Fetches and decodes the GTFS-RT FeedMessage containing real-time train data
    func fetchFeed() async throws -> TransitRealtime_FeedMessage
    
    /// Downloads the base subway data ZIP file from AWS S3
    func fetchBaseData() async throws
    
    /// Processes and persists the base subway data to SwiftData
    func decodeBaseData(context: ModelContext?) async throws
}

/**
 * Protocol for GTFS data processing operations
 * 
 * This protocol separates the data transformation logic from the service layer,
 * making it easier to test and maintain the complex GTFS-RT processing logic.
 */
protocol GTFSDataProcessorProtocol {
    /// Processes a GTFS-RT feed into an array of train positions
    func processTrainPositions(from feed: TransitRealtime_FeedMessage) -> [TrainPosition]
    
    /// Extracts stop information from a trip update
    func extractStopInfos(from tripUpdate: TransitRealtime_TripUpdate) -> [StopInfo]
    
    /// Creates a train position from available GTFS-RT data
    func createTrainPosition(
        tripId: String,
        vehicle: TransitRealtime_VehiclePosition?,
        tripUpdate: TransitRealtime_TripUpdate?
    ) -> TrainPosition?
}

/**
 * Protocol for station name resolution
 * 
 * This protocol handles the mapping from GTFS stop IDs to human-readable
 * station names and coordinates, enabling easy testing and customization.
 */
protocol StationNameResolverProtocol {
    /// Resolves a human-readable name for a given stop ID
    func resolveName(for stopId: String) -> String
    
    /// Resolves coordinates for a given stop ID
    func resolveCoordinate(for stopId: String) -> (latitude: Double, longitude: Double)?
}

/**
 * Protocol for URL session operations
 * 
 * This protocol enables testing of network operations by providing a
 * mockable interface for URLSession functionality.
 */
protocol URLSessionProtocol {
    /// Performs a data task for a given URL
    func data(from url: URL) async throws -> (Data, URLResponse)
    
    /// Performs a data task for a given request
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

// MARK: - URLSession Protocol Conformance

extension URLSession: URLSessionProtocol {
    // URLSession already implements these methods, so no additional implementation needed
}