//
//  TrainPosition.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/16/25.
//

import Foundation
import CoreLocation

struct TrainPosition: Identifiable {
    let id: String
    let tripId: String
    let routeId: String
    let trainId: String?
    let direction: String
    let isAssigned: Bool
    let currentStopId: String?
    let currentStatus: String
    let lastMovementTimestamp: Date?
    let nextStops: [StopInfo]
    
    // Computed properties for easier access
    var lastStation: String {
        // Extract the last station from current stop or previous stops
        if let currentStop = currentStopId {
            return extractStationName(from: currentStop)
        }
        return "Unknown"
    }
    
    var nextStation: String {
        // Get the next station from the upcoming stops
        if let firstUpcomingStop = nextStops.first {
            return extractStationName(from: firstUpcomingStop.stopId)
        }
        return "Unknown"
    }
    
    var displayName: String {
        return "\(routeId) Train"
    }
    
    var directionName: String {
        switch direction.uppercased() {
        case "NORTH", "N":
            return "Uptown/Bronx"
        case "SOUTH", "S":
            return "Downtown/Brooklyn"
        default:
            return direction
        }
    }
    
    // Helper function to extract readable station name from stop ID
    private func extractStationName(from stopId: String) -> String {
        // Stop IDs in NYCT format are like "613N" (station + direction)
        // You would need a mapping from stop IDs to station names
        // For now, return the stop ID without direction suffix
        let cleanId = stopId.replacingOccurrences(of: "[NS]$", with: "", options: .regularExpression)
        return "Station \(cleanId)" // Replace with actual station name lookup
    }
}

struct StopInfo {
    let stopId: String
    let arrivalTime: Date?
    let departureTime: Date?
    let scheduledTrack: String?
    let actualTrack: String?
    
    var stationName: String {
        // Same helper logic as above
        let cleanId = stopId.replacingOccurrences(of: "[NS]$", with: "", options: .regularExpression)
        return "Station \(cleanId)"
    }
}

