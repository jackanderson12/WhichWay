//
//  gtfs-extensions.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/18/25.
//

import Foundation

// MARK: - Extensions for easier handling of GTFS-RT data

extension TransitRealtime_VehiclePosition.VehicleStopStatus {
    var description: String {
        switch self {
        case .incomingAt:
            return "Incoming"
        case .stoppedAt:
            return "Stopped"
        case .inTransitTo:
            return "In Transit"
        }
    }
}

extension TransitRealtime_NyctTripDescriptor.Direction {
    var shortName: String {
        switch self {
        case .north: return "N"
        case .south: return "S"
        case .east: return "E"
        case .west: return "W"
        }
    }
    
    var fullName: String {
        switch self {
        case .north: return "Uptown/Bronx"
        case .south: return "Downtown/Brooklyn"
        case .east: return "East"
        case .west: return "West"
        }
    }
}

// MARK: - Helper functions for parsing NYCT trip IDs

extension String {
    /// Parses NYCT trip ID format like "021150_2..N08R"
    /// Returns (startTime, routeId, direction, pathId)
    func parseNYCTTripId() -> (startTime: String?, routeId: String?, direction: String?, pathId: String?) {
        let components = self.components(separatedBy: "_")
        guard components.count >= 2 else {
            return (nil, nil, nil, nil)
        }
        
        let startTime = components[0]
        let pathInfo = components[1]
        
        // Parse path info like "2..N08R"
        // Route is typically the first character(s)
        // Direction is N/S
        // Path ID is the rest
        
        var routeId: String?
        var direction: String?
        var pathId: String?
        
        if let directionIndex = pathInfo.firstIndex(where: { $0 == "N" || $0 == "S" }) {
            routeId = String(pathInfo[..<directionIndex]).replacingOccurrences(of: ".", with: "")
            direction = String(pathInfo[directionIndex])
            pathId = String(pathInfo[pathInfo.index(after: directionIndex)...])
        }
        
        return (startTime, routeId, direction, pathId)
    }
}

// MARK: - Station name mapping helper

class StationNameMapper {
    // This would ideally be populated from the GTFS stops.txt file
    // For now, providing a few examples
    private static let stationNames: [String: String] = [
        "613": "Hunts Point Ave",
        "612": "Longwood Ave",
        "611": "East 149th St",
        "610": "Melrose",
        "609": "East 143rd St",
        // Add more mappings as needed
    ]
    
    static func stationName(for stopId: String) -> String {
        // Remove direction suffix (N/S)
        let cleanId = stopId.replacingOccurrences(of: "[NS]$", with: "", options: .regularExpression)
        return stationNames[cleanId] ?? "Station \(cleanId)"
    }
}
