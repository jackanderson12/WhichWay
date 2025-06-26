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

class MapViewModel: ObservableObject {
    @Published var trainPositions: [TrainPosition] = []
    private let service = MTAService()

    init() {
        Task {
            await fetchTrainPositions()
        }
    }

    /// Fetches GTFS-RT feed and maps it into TrainPosition models.
    @MainActor
    func fetchTrainPositions() async {
        do {
            let feed = try await service.fetchFeed()
            
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
            var newPositions: [TrainPosition] = []
            
            // Process vehicles with positions
            for (tripId, vehicle) in vehiclePositions {
                if let trainPosition = createTrainPosition(
                    tripId: tripId,
                    vehicle: vehicle,
                    tripUpdate: tripUpdates[tripId]
                ) {
                    newPositions.append(trainPosition)
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
                        newPositions.append(trainPosition)
                    }
                }
            }
            
            self.trainPositions = newPositions
            print("Successfully parsed \(newPositions.count) train positions")
            print(trainPositions[0])
            
        } catch {
            print("Error fetching train positions:", error)
        }
    }
    
    /// Creates a TrainPosition from available GTFS-RT data
    private func createTrainPosition(
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
            switch nyctDirection {
            case .north:
                direction = "N"
            case .south:
                direction = "S"
            case .east:
                direction = "E"
            case .west:
                direction = "W"
            }
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
        let nextStops = extractStopInfos(from: tripUpdate)
        
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
    
    /// Extracts stop information from trip updates
    private func extractStopInfos(from tripUpdate: TransitRealtime_TripUpdate?) -> [StopInfo] {
        guard let tripUpdate = tripUpdate else { return [] }
        
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
}
