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

// MARK: - Subway Route Polylines (Memory Efficient)

/// Represents a subway route polyline with coordinates
@Model
final class SubwayRoutePolyline: Identifiable, Equatable {
    var id: String
    var routeId: String
    private var _coordinates: [Coordinate]
    
    /// Access coordinates as CLLocationCoordinate2D array
    var coordinates: [CLLocationCoordinate2D] {
        get {
            _coordinates.map { $0.clLocationCoordinate2D }
        }
        set {
            _coordinates = newValue.map { Coordinate(from: $0) }
        }
    }

    // computed, so it's not part of synthesis
    var polyline: MKPolyline {
        MKPolyline(coordinates: coordinates, count: coordinates.count)
    }

    init(routeId: String, coordinates: [CLLocationCoordinate2D]) {
        self.id = routeId
        self.routeId = routeId
        self._coordinates = coordinates.map { Coordinate(from: $0) }
    }
}

// MARK: - Coordinate Wrapper

/// A wrapper for CLLocationCoordinate2D that provides Codable conformance
/// This avoids extending imported types with protocol conformances
struct Coordinate: Codable, Equatable {
    let latitude: Double
    let longitude: Double
    
    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    init(from coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
    
    /// Converts this wrapper back to CLLocationCoordinate2D
    var clLocationCoordinate2D: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}


