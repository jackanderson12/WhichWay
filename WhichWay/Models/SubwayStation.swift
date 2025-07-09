//
//  SubwayStation.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/24/25.
//


import Foundation
import CoreLocation
import SwiftData

// MARK: - Subway Station Models

/**
 * SubwayStation - SwiftData model representing a NYC subway station
 * 
 * This model stores persistent information about subway stations that doesn't
 * change frequently, such as location coordinates and station names. It's
 * designed for efficient storage and retrieval from SwiftData.
 * 
 * ## Features:
 * - Persistent storage in SwiftData
 * - Geographic coordinate support
 * - Distance calculations
 * - Map integration compatibility
 * - Efficient equality comparison
 * 
 * ## Data Source:
 * Station data is derived from MTA's GTFS stops.txt file, which contains
 * all subway stations with their coordinates and metadata.
 * 
 * ## Performance:
 * - Marked as `final` for performance optimization
 * - Uses primitive types for efficient SwiftData storage
 * - Computed properties for derived values
 * - Lazy coordinate conversions
 * 
 * ## Usage:
 * Stations are loaded once from GTFS data and stored persistently.
 * They're queried by SwiftUI views for map display and route calculations.
 */
@Model
final class SubwayStation: Identifiable, Equatable {
    
    // MARK: - Stored Properties
    
    /// Unique station identifier from GTFS data
    /// Format: Usually numeric (e.g., "101", "R16") from stops.txt
    var id: String
    
    /// Human-readable station name
    /// Example: "Times Sq-42 St", "14 St-Union Sq"
    var name: String
    
    /// Station latitude in decimal degrees
    /// Range: Approximately 40.4 to 40.9 for NYC area
    var latitude: Double
    
    /// Station longitude in decimal degrees  
    /// Range: Approximately -74.3 to -73.7 for NYC area
    var longitude: Double
    
    // MARK: - Initialization
    
    /**
     * Creates a new subway station instance
     * 
     * ## Parameters:
     * - id: Unique identifier from GTFS stops.txt
     * - name: Display name for the station
     * - latitude: GPS latitude coordinate
     * - longitude: GPS longitude coordinate
     * 
     * ## Example:
     * ```swift
     * let station = SubwayStation(
     *     id: "101",
     *     name: "Times Sq-42 St",
     *     latitude: 40.755477,
     *     longitude: -73.987691
     * )
     * ```
     */
    init(id: String, name: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // MARK: - Equatable Conformance
    
    /**
     * Determines equality based on unique station ID
     * 
     * Two stations are considered equal if they have the same ID,
     * regardless of other properties. This is efficient for SwiftData
     * operations and prevents duplicate stations.
     */
    static func == (lhs: SubwayStation, rhs: SubwayStation) -> Bool {
        return lhs.id == rhs.id
    }
    
    // MARK: - Computed Properties
    
    /**
     * Returns the station location as a CLLocationCoordinate2D
     * 
     * This is the primary interface for MapKit integration,
     * allowing stations to be displayed as map markers.
     * 
     * ## Returns:
     * CLLocationCoordinate2D suitable for MapKit usage
     */
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /**
     * Returns the station location as a CLLocation
     * 
     * Provides a full CLLocation object for advanced location operations
     * like bearing calculations and geographic computations.
     * 
     * ## Returns:
     * CLLocation with station coordinates and current timestamp
     */
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    // MARK: - Distance Calculation Methods
    
    /**
     * Calculates the distance to another subway station
     * 
     * Uses CoreLocation's distance calculation which accounts for
     * the Earth's curvature and provides accurate results for
     * the relatively short distances between NYC subway stations.
     * 
     * ## Parameters:
     * - otherStation: The destination station
     * 
     * ## Returns:
     * Distance in meters between the two stations
     * 
     * ## Example:
     * ```swift
     * let distance = timesSquare.distance(to: unionSquare)
     * print("Distance: \(distance) meters") // ~2400 meters
     * ```
     */
    func distance(to otherStation: SubwayStation) -> CLLocationDistance {
        return location.distance(from: otherStation.location)
    }
    
    /**
     * Calculates the distance to a specific coordinate
     * 
     * Useful for finding the nearest station to a user's location
     * or calculating distances to arbitrary points on the map.
     * 
     * ## Parameters:
     * - coordinate: The target coordinate
     * 
     * ## Returns:
     * Distance in meters from the station to the coordinate
     * 
     * ## Example:
     * ```swift
     * let userLocation = CLLocationCoordinate2D(latitude: 40.7505, longitude: -73.9934)
     * let distance = station.distance(to: userLocation)
     * ```
     */
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let otherLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location.distance(from: otherLocation)
    }
}
