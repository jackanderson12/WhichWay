//
//  GTFSDataProcessor.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/9/25.
//

import Foundation

// MARK: - GTFS Data Processor

class GTFSDataProcessor: GTFSDataProcessorProtocol {

    private let stationResolver: StationNameResolverProtocol

    init(stationResolver: StationNameResolverProtocol = StationNameResolver()) {
        self.stationResolver = stationResolver
    }

    // MARK: - Feed Processing

    func processTrainPositions(from feed: TransitRealtime_FeedMessage) -> [TrainPosition] {
        var vehiclePositions: [String: TransitRealtime_VehiclePosition] = [:]
        var tripUpdates: [String: TransitRealtime_TripUpdate] = [:]

        for entity in feed.entity {
            if entity.hasVehicle && entity.vehicle.hasTrip {
                vehiclePositions[entity.vehicle.trip.tripID] = entity.vehicle
            }
            if entity.hasTripUpdate {
                tripUpdates[entity.tripUpdate.trip.tripID] = entity.tripUpdate
            }
        }

        var trainPositions: [TrainPosition] = []

        for (tripId, vehicle) in vehiclePositions {
            if let pos = createTrainPosition(tripId: tripId, vehicle: vehicle, tripUpdate: tripUpdates[tripId]) {
                trainPositions.append(pos)
            }
        }

        for (tripId, tripUpdate) in tripUpdates where vehiclePositions[tripId] == nil {
            if let pos = createTrainPosition(tripId: tripId, vehicle: nil, tripUpdate: tripUpdate) {
                trainPositions.append(pos)
            }
        }

        return trainPositions
    }

    func processAllFeeds(_ feeds: [TransitRealtime_FeedMessage]) -> [TrainPosition] {
        return feeds.flatMap { processTrainPositions(from: $0) }
    }

    // MARK: - Arrival Extraction

    func extractArrivals(
        for stationId: String,
        childStopIds: [String],
        from feeds: [TransitRealtime_FeedMessage],
        routeColors: [String: (color: String, textColor: String)]
    ) -> [StationArrival] {
        let stopIdSet = Set(childStopIds)
        let now = Date()
        var arrivals: [StationArrival] = []

        for feed in feeds {
            for entity in feed.entity {
                guard entity.hasTripUpdate else { continue }
                let tripUpdate = entity.tripUpdate
                let trip = tripUpdate.trip
                let routeId = trip.routeID

                // Determine direction from NYCT extension
                let direction: String
                if trip.hasTransitRealtime_nyctTripDescriptor {
                    direction = convertDirection(trip.TransitRealtime_nyctTripDescriptor.direction)
                } else {
                    direction = "Unknown"
                }

                for stopTimeUpdate in tripUpdate.stopTimeUpdate {
                    guard stopIdSet.contains(stopTimeUpdate.stopID) else { continue }

                    guard stopTimeUpdate.hasArrival, stopTimeUpdate.arrival.hasTime else { continue }

                    let arrivalTime = Date(timeIntervalSince1970: TimeInterval(stopTimeUpdate.arrival.time))
                    guard arrivalTime > now else { continue }

                    // Also infer direction from stop ID suffix if NYCT direction unavailable
                    let effectiveDirection: String
                    if direction == "Unknown" {
                        if stopTimeUpdate.stopID.hasSuffix("N") { effectiveDirection = "N" }
                        else if stopTimeUpdate.stopID.hasSuffix("S") { effectiveDirection = "S" }
                        else { effectiveDirection = direction }
                    } else {
                        effectiveDirection = direction
                    }

                    let colors = routeColors[routeId]

                    let arrival = StationArrival(
                        id: "\(trip.tripID)_\(stopTimeUpdate.stopID)",
                        routeId: routeId,
                        routeShortName: routeId,
                        routeColor: colors?.color ?? "808080",
                        routeTextColor: colors?.textColor ?? "FFFFFF",
                        direction: effectiveDirection,
                        directionLabel: effectiveDirection == "N" ? "Uptown/Bronx" : "Downtown/Brooklyn",
                        arrivalTime: arrivalTime,
                        tripId: trip.tripID
                    )

                    arrivals.append(arrival)
                }
            }
        }

        return arrivals.sorted { $0.arrivalTime < $1.arrivalTime }
    }

    // MARK: - Stop Info Extraction

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

    // MARK: - Train Position Creation

    func createTrainPosition(
        tripId: String,
        vehicle: TransitRealtime_VehiclePosition?,
        tripUpdate: TransitRealtime_TripUpdate?
    ) -> TrainPosition? {
        guard let trip = vehicle?.trip ?? tripUpdate?.trip else { return nil }

        let nyctTripDescriptor = trip.hasTransitRealtime_nyctTripDescriptor ?
            trip.TransitRealtime_nyctTripDescriptor : nil

        let direction: String
        if let nyctDirection = nyctTripDescriptor?.direction {
            direction = convertDirection(nyctDirection)
        } else {
            direction = "Unknown"
        }

        let currentStopId = vehicle?.hasStopID == true ? vehicle?.stopID : nil
        let currentStatus = (vehicle?.hasCurrentStatus == true ?
                             vehicle?.currentStatus.rawValue.description : "Unknown") ?? "Unknown"

        let lastMovementTimestamp = vehicle?.hasTimestamp == true ?
            Date(timeIntervalSince1970: TimeInterval(vehicle!.timestamp)) : nil

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

    // MARK: - Helpers

    private func convertDirection(_ direction: TransitRealtime_NyctTripDescriptor.Direction) -> String {
        switch direction {
        case .north: return "N"
        case .south: return "S"
        case .east: return "E"
        case .west: return "W"
        default: return "Unknown"
        }
    }
}
