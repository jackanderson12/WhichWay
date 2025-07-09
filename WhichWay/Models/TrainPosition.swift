//
//  TrainPosition.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/16/25.
//

import Foundation
import CoreLocation

// MARK: - Train Position Models

/**
 * TrainPosition - Real-time train location and status information
 * 
 * This struct represents the current state of a subway train, combining
 * vehicle position data with trip updates from the MTA's GTFS-RT feed.
 * It's designed for real-time updates and efficient UI rendering.
 * 
 * ## Features:
 * - Real-time position and status tracking
 * - User-friendly display properties
 * - Integration with GTFS-RT data structures
 * - Efficient updates without persistent storage
 * 
 * ## Data Source:
 * Created from MTA's GTFS-RT feed by combining:
 * - Vehicle positions (GPS coordinates, current stop)
 * - Trip updates (schedule adherence, next stops)
 * - NYC-specific extensions (train IDs, direction)
 * 
 * ## Usage:
 * Train positions are updated frequently (every 30 seconds) and are
 * used for live map display, arrival predictions, and service status.
 * 
 * ## Performance:
 * - Lightweight struct for efficient copying
 * - Computed properties for derived values
 * - Minimal memory footprint for real-time updates
 */
struct TrainPosition: Identifiable {
    
    // MARK: - Core Properties
    
    /// Unique identifier for this train position (typically trip ID)
    let id: String
    
    /// GTFS trip identifier for this specific train run
    let tripId: String
    
    /// Route identifier (e.g., "4", "6", "L", "N")
    let routeId: String
    
    /// NYC-specific train identifier (e.g., "1234" for train consist)
    /// Optional because not all trains have assigned IDs
    let trainId: String?
    
    /// Direction of travel (N/S/E/W)
    let direction: String
    
    /// Whether this train is assigned to active service
    let isAssigned: Bool
    
    /// Current stop ID if train is at a station
    let currentStopId: String?
    
    /// Current movement status (e.g., "STOPPED_AT", "IN_TRANSIT_TO")
    let currentStatus: String
    
    /// Timestamp of last recorded movement
    let lastMovementTimestamp: Date?
    
    /// Array of upcoming stops with arrival predictions
    let nextStops: [StopInfo]
    
    // MARK: - Computed Properties for UI Display
    
    /**
     * Last station name for display
     * 
     * Extracts a readable station name from the current stop ID.
     * This is used for "Last seen at..." type displays.
     * 
     * ## Returns:
     * Human-readable station name or "Unknown" if unavailable
     */
    var lastStation: String {
        if let currentStop = currentStopId {
            return extractStationName(from: currentStop)
        }
        return "Unknown"
    }
    
    /**
     * Next station name for display
     * 
     * Gets the next station from the upcoming stops array.
     * This is used for "Next stop..." type displays.
     * 
     * ## Returns:
     * Human-readable next station name or "Unknown" if unavailable
     */
    var nextStation: String {
        if let firstUpcomingStop = nextStops.first {
            return extractStationName(from: firstUpcomingStop.stopId)
        }
        return "Unknown"
    }
    
    /**
     * Display name for train identification
     * 
     * Creates a user-friendly train identifier for UI display.
     * 
     * ## Returns:
     * Formatted string like "4 Train" or "L Train"
     */
    var displayName: String {
        return "\(routeId) Train"
    }
    
    /**
     * User-friendly direction name
     * 
     * Converts compass directions to NYC-specific directional names
     * that users understand (Uptown/Downtown, etc.).
     * 
     * ## Returns:
     * NYC-style direction name for user display
     */
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
    
    // MARK: - Helper Methods
    
    /**
     * Extracts readable station name from stop ID
     * 
     * GTFS stop IDs in NYC format include direction suffixes (e.g., "613N").
     * This method removes the suffix to get the base station identifier.
     * 
     * ## Parameters:
     * - stopId: GTFS stop ID with potential direction suffix
     * 
     * ## Returns:
     * Cleaned station identifier suitable for display
     * 
     * ## Note:
     * This is a temporary implementation. In a production app, you would
     * maintain a mapping from stop IDs to actual station names.
     */
    private func extractStationName(from stopId: String) -> String {
        // Stop IDs in NYCT format are like "613N" (station + direction)
        // Remove direction suffix to get base station ID
        let cleanId = stopId.replacingOccurrences(of: "[NS]$", with: "", options: .regularExpression)
        return "Station \(cleanId)" // TODO: Replace with actual station name lookup
    }
}

// MARK: - Stop Information Model

/**
 * StopInfo - Information about a train's upcoming stop
 * 
 * This struct contains arrival and departure predictions for a specific
 * stop along a train's route, including track assignments and timing.
 * 
 * ## Features:
 * - Arrival and departure time predictions
 * - Track assignment information
 * - Station name extraction
 * - Schedule adherence data
 * 
 * ## Data Source:
 * Created from GTFS-RT trip updates which contain stop time predictions
 * and NYC-specific track assignment extensions.
 * 
 * ## Usage:
 * Used within TrainPosition objects to provide users with upcoming
 * stop information and arrival predictions.
 */
struct StopInfo {
    
    // MARK: - Properties
    
    /// GTFS stop identifier
    let stopId: String
    
    /// Predicted arrival time at this stop
    let arrivalTime: Date?
    
    /// Predicted departure time from this stop
    let departureTime: Date?
    
    /// Scheduled track assignment from timetable
    let scheduledTrack: String?
    
    /// Actual track assignment (real-time update)
    let actualTrack: String?
    
    // MARK: - Computed Properties
    
    /**
     * Station name for display
     * 
     * Extracts a readable station name from the stop ID using the same
     * logic as TrainPosition.extractStationName().
     * 
     * ## Returns:
     * Human-readable station name for UI display
     */
    var stationName: String {
        let cleanId = stopId.replacingOccurrences(of: "[NS]$", with: "", options: .regularExpression)
        return "Station \(cleanId)" // TODO: Replace with actual station name lookup
    }
}

