//
//  SubwayRoutePolylines.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/26/25.
//
import Foundation
import CoreLocation
import MapKit
import SwiftData

// MARK: - Subway Route Polylines

/**
 * SubwayRoutePolyline - SwiftData model for subway route visual paths
 * 
 * This model stores the geographic path of subway routes as a series of
 * coordinate points, enabling visual route representation on maps.
 * It's optimized for SwiftData storage while maintaining MapKit compatibility.
 * 
 * ## Features:
 * - Memory-efficient coordinate storage using wrapper structs
 * - SwiftData persistence with automatic serialization
 * - MapKit integration via MKPolyline generation
 * - Route-based organization for efficient querying
 * 
 * ## Data Source:
 * Polyline data is derived from MTA's GTFS shapes.txt file, which contains
 * the geographic path of each subway route with detailed coordinate sequences.
 * 
 * ## Storage Strategy:
 * - Uses custom Coordinate wrapper to avoid extending imported types
 * - Stores coordinates as private array for SwiftData compatibility
 * - Provides computed properties for external access
 * - Enables efficient database operations and memory usage
 * 
 * ## Performance:
 * - Marked as `final` for compiler optimization
 * - Lazy polyline generation only when needed
 * - Efficient coordinate transformation using map operations
 */
@Model
final class SubwayRoutePolyline: Identifiable, Equatable {
    
    // MARK: - Stored Properties
    
    /// Unique identifier for the polyline (matches route ID)
    var id: String
    
    /// Associated subway route identifier (e.g., "4", "6", "L")
    var routeId: String
    
    /// Internal coordinate storage using SwiftData-compatible wrapper
    /// Private to enforce controlled access through computed property
    private var _coordinates: [Coordinate]
    
    // MARK: - Computed Properties
    
    /**
     * Access coordinates as CLLocationCoordinate2D array
     * 
     * Provides transparent access to route coordinates while maintaining
     * SwiftData storage efficiency. The getter converts from internal
     * Coordinate wrappers to MapKit-compatible CLLocationCoordinate2D.
     * 
     * ## Getter:
     * Transforms internal Coordinate structs to CLLocationCoordinate2D
     * 
     * ## Setter:
     * Transforms CLLocationCoordinate2D to internal Coordinate structs
     * 
     * ## Usage:
     * ```swift
     * let polyline = SubwayRoutePolyline(routeId: "4", coordinates: coords)
     * let mapCoordinates = polyline.coordinates // Get CLLocationCoordinate2D[]
     * polyline.coordinates = newCoords // Set from CLLocationCoordinate2D[]
     * ```
     */
    var coordinates: [CLLocationCoordinate2D] {
        get {
            _coordinates.map { $0.clLocationCoordinate2D }
        }
        set {
            _coordinates = newValue.map { Coordinate(from: $0) }
        }
    }

    /**
     * Generates an MKPolyline for MapKit rendering
     * 
     * Creates a MapKit-compatible polyline object from the stored coordinates.
     * This is a computed property to avoid storing redundant data and
     * ensure the polyline reflects current coordinate state.
     * 
     * ## Returns:
     * MKPolyline ready for map display and styling
     * 
     * ## Usage:
     * ```swift
     * let mapPolyline = routePolyline.polyline
     * mapView.addOverlay(mapPolyline)
     * ```
     * 
     * ## Performance:
     * - Computed each time to ensure data consistency
     * - Minimal overhead for typical route sizes (hundreds of points)
     * - MapKit handles rendering optimization
     */
    var polyline: MKPolyline {
        MKPolyline(coordinates: coordinates, count: coordinates.count)
    }

    // MARK: - Initialization
    
    /**
     * Creates a new subway route polyline
     * 
     * ## Parameters:
     * - routeId: Subway route identifier (e.g., "4", "6", "L")
     * - coordinates: Array of geographic points defining the route path
     * 
     * ## Example:
     * ```swift
     * let coordinates = [
     *     CLLocationCoordinate2D(latitude: 40.7831, longitude: -73.9712),
     *     CLLocationCoordinate2D(latitude: 40.7589, longitude: -73.9851)
     * ]
     * let polyline = SubwayRoutePolyline(routeId: "N", coordinates: coordinates)
     * ```
     */
    init(routeId: String, coordinates: [CLLocationCoordinate2D]) {
        self.id = routeId
        self.routeId = routeId
        self._coordinates = coordinates.map { Coordinate(from: $0) }
    }
}

// MARK: - Coordinate Wrapper

/**
 * Coordinate - SwiftData-compatible wrapper for CLLocationCoordinate2D
 * 
 * This wrapper struct provides Codable conformance for geographic coordinates
 * while avoiding extension of imported Core Location types. It enables
 * efficient storage in SwiftData while maintaining compatibility with MapKit.
 * 
 * ## Design Rationale:
 * - Avoids extending imported types with protocol conformances
 * - Provides clean separation between storage and usage types
 * - Enables SwiftData automatic serialization
 * - Maintains type safety and conversion clarity
 * 
 * ## Features:
 * - Codable conformance for SwiftData storage
 * - Equatable conformance for efficient comparisons
 * - Seamless conversion to/from CLLocationCoordinate2D
 * - Lightweight struct with minimal overhead
 */
struct Coordinate: Codable, Equatable {
    
    // MARK: - Properties
    
    /// Latitude in decimal degrees
    let latitude: Double
    
    /// Longitude in decimal degrees
    let longitude: Double
    
    // MARK: - Initialization
    
    /**
     * Creates a coordinate with explicit latitude and longitude
     * 
     * ## Parameters:
     * - latitude: Latitude in decimal degrees
     * - longitude: Longitude in decimal degrees
     */
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    /**
     * Creates a coordinate from CLLocationCoordinate2D
     * 
     * Convenience initializer for converting from MapKit/CoreLocation
     * coordinate types to the SwiftData-compatible wrapper.
     * 
     * ## Parameters:
     * - coordinate: Source CLLocationCoordinate2D to convert
     */
    init(from coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    // MARK: - Computed Properties
    
    /**
     * Converts this wrapper back to CLLocationCoordinate2D
     * 
     * Provides seamless conversion to MapKit-compatible coordinate type
     * for use in map operations and geographic calculations.
     * 
     * ## Returns:
     * CLLocationCoordinate2D with matching latitude and longitude
     */
    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}


