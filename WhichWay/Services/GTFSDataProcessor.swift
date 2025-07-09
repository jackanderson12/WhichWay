//
//  GTFSDataProcessor.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/9/25.
//

import Foundation

// MARK: - GTFS Data Processor

/**
 * GTFSDataProcessor - Handles transformation of GTFS-RT data into app models
 * 
 * This class separates the complex data processing logic from the service layer,
 * making it easier to test and maintain the GTFS-RT feed processing functionality.
 * 
 * ## Key Responsibilities:
 * - Parse GTFS-RT protobuf data into Swift models
 * - Handle NYC-specific extensions and data formats
 * - Process vehicle positions and trip updates
 * - Create complete train position objects
 * - Extract stop time information
 * 
 * ## Design Benefits:
 * - Testable without network dependencies
 * - Focused single responsibility
 * - Reusable across different contexts
 * - Easy to mock for testing
 */
class GTFSDataProcessor: GTFSDataProcessorProtocol {
    
    // MARK: - Dependencies
    
    private let stationResolver: StationNameResolverProtocol
    
    // MARK: - Initialization
    
    /**
     * Initializes the processor with required dependencies
     * 
     * ## Parameters:
     * - stationResolver: Service for resolving station names from stop IDs
     */
    init(stationResolver: StationNameResolverProtocol = StationNameResolver()) {
        self.stationResolver = stationResolver
    }
    
    // MARK: - GTFSDataProcessorProtocol Implementation
    
    /**
     * Processes a GTFS-RT feed into an array of train positions
     * 
     * This method performs the core data transformation from raw GTFS-RT
     * protobuf data into structured TrainPosition objects suitable for
     * map visualization and user interaction.
     * 
     * ## Processing Steps:
     * 1. Parse vehicle positions and trip updates from the feed
     * 2. Cross-reference data to build complete train records
     * 3. Extract NYC-specific extensions (train IDs, directions)
     * 4. Generate user-friendly train position objects
     * 
     * ## Parameters:
     * - feed: The GTFS-RT feed message to process
     * 
     * ## Returns:
     * Array of TrainPosition objects with complete train data
     */
    func processTrainPositions(from feed: TransitRealtime_FeedMessage) -> [TrainPosition] {
        // Create dictionaries to match vehicle positions with trip updates
        var vehiclePositions: [String: TransitRealtime_VehiclePosition] = [:]
        var tripUpdates: [String: TransitRealtime_TripUpdate] = [:]
        
        // First pass: collect all vehicle positions and trip updates
        for entity in feed.entity {
            if entity.hasVehicle {
                let vehicle = entity.vehicle
                if vehicle.hasTrip {
                    vehiclePositions[vehicle.trip.tripID] = vehicle
                }
            }
            
            if entity.hasTripUpdate {
                let tripUpdate = entity.tripUpdate
                tripUpdates[tripUpdate.trip.tripID] = tripUpdate
            }
        }
        
        // Second pass: create TrainPosition objects by combining data
        var trainPositions: [TrainPosition] = []
        
        // Process vehicles with positions
        for (tripId, vehicle) in vehiclePositions {
            if let trainPosition = createTrainPosition(
                tripId: tripId,
                vehicle: vehicle,
                tripUpdate: tripUpdates[tripId]
            ) {
                trainPositions.append(trainPosition)
            }
        }
        
        // Process trip updates that don't have vehicle positions yet
        for (tripId, tripUpdate) in tripUpdates {
            if vehiclePositions[tripId] == nil {
                if let trainPosition = createTrainPosition(
                    tripId: tripId,
                    vehicle: nil,
                    tripUpdate: tripUpdate
                ) {
                    trainPositions.append(trainPosition)
                }
            }
        }
        
        return trainPositions
    }
    
    /**
     * Extracts stop information from trip updates
     * 
     * Processes the stop time updates from a trip update to create an array
     * of StopInfo objects containing arrival/departure predictions and
     * track assignments.
     * 
     * ## Parameters:
     * - tripUpdate: Trip update containing stop time information
     * 
     * ## Returns:
     * Array of StopInfo objects with stop predictions and track data
     */
    func extractStopInfos(from tripUpdate: TransitRealtime_TripUpdate) -> [StopInfo] {
        return tripUpdate.stopTimeUpdate.compactMap { stopTimeUpdate in
            let nyctStopTimeUpdate = stopTimeUpdate.hasTransitRealtime_nyctStopTimeUpdate ?
                stopTimeUpdate.TransitRealtime_nyctStopTimeUpdate : nil
            
            let arrivalTime = stopTimeUpdate.hasArrival && stopTimeUpdate.arrival.hasTime ?
                Date(timeIntervalSince1970: TimeInterval(stopTimeUpdate.arrival.time)) : nil
            
            let departureTime = stopTimeUpdate.hasDeparture && stopTimeUpdate.departure.hasTime ?
                Date(timeIntervalSince1970: TimeInterval(stopTimeUpdate.departure.time)) : nil
            
            return StopInfo(
                stopId: stopTimeUpdate.stopID,
                arrivalTime: arrivalTime,
                departureTime: departureTime,
                scheduledTrack: nyctStopTimeUpdate?.scheduledTrack,
                actualTrack: nyctStopTimeUpdate?.actualTrack
            )
        }
    }
    
    /**
     * Creates a TrainPosition from available GTFS-RT data
     * 
     * This method combines vehicle position data with trip update information
     * to create a complete train record. It handles cases where only partial
     * data is available and extracts NYC-specific information.
     * 
     * ## Parameters:
     * - tripId: Unique identifier for the trip
     * - vehicle: Optional vehicle position with GPS coordinates
     * - tripUpdate: Optional trip update with schedule information
     * 
     * ## Returns:
     * A TrainPosition object if sufficient data is available, nil otherwise
     */
    func createTrainPosition(
        tripId: String,
        vehicle: TransitRealtime_VehiclePosition?,
        tripUpdate: TransitRealtime_TripUpdate?
    ) -> TrainPosition? {
        
        // We need at least a trip descriptor
        guard let trip = vehicle?.trip ?? tripUpdate?.trip else {
            return nil
        }
        
        // Extract NYCT-specific extensions
        let nyctTripDescriptor = trip.hasTransitRealtime_nyctTripDescriptor ?
            trip.TransitRealtime_nyctTripDescriptor : nil
        
        // Determine direction
        let direction: String
        if let nyctDirection = nyctTripDescriptor?.direction {
            direction = convertDirection(nyctDirection)
        } else {
            direction = "Unknown"
        }
        
        // Extract current stop information from vehicle position
        let currentStopId = vehicle?.hasStopID == true ? vehicle?.stopID : nil
        let currentStatus = (vehicle?.hasCurrentStatus == true ?
                             vehicle?.currentStatus.rawValue.description : "Unknown") ?? "Unknown"
        
        // Extract timestamp
        let lastMovementTimestamp = vehicle?.hasTimestamp == true ?
            Date(timeIntervalSince1970: TimeInterval(vehicle!.timestamp)) : nil
        
        // Extract stop time updates
        let nextStops = tripUpdate != nil ? extractStopInfos(from: tripUpdate!) : []
        
        return TrainPosition(
            id: tripId,
            tripId: tripId,
            routeId: trip.routeID,
            trainId: nyctTripDescriptor?.trainID,
            direction: direction,
            isAssigned: nyctTripDescriptor?.isAssigned ?? false,
            currentStopId: currentStopId,
            currentStatus: currentStatus,
            lastMovementTimestamp: lastMovementTimestamp,
            nextStops: nextStops
        )
    }
    
    // MARK: - Private Helper Methods
    
    /**
     * Converts GTFS-RT direction enum to string representation
     * 
     * ## Parameters:
     * - direction: GTFS-RT direction enum value
     * 
     * ## Returns:
     * String representation of the direction (N/S/E/W)
     */
    private func convertDirection(_ direction: TransitRealtime_NyctTripDescriptor.Direction) -> String {
        switch direction {
        case .north:
            return "N"
        case .south:
            return "S"
        case .east:
            return "E"
        case .west:
            return "W"
        default:
            return "Unknown"
        }
    }
}