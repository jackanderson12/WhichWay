//
//  SubwayStation.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/24/25.
//


import Foundation
import CoreLocation
import SwiftData

// MARK: - Subway Station Models, Storing in Swift Data as information does not need to be updated as frequently

/// Represents a NYC subway station
@Model
final class SubwayStation: Identifiable, Equatable {
    var id: String
    var name: String
    var latitude: Double
    var longitude: Double
    
    static func == (lhs: SubwayStation, rhs: SubwayStation) -> Bool {
        return lhs.id == rhs.id
    }
    
    init(id: String, name: String, latitude: Double, longitude: Double) {
        self.id = id
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // MARK: - Computed Properties
    
    /// Returns the coordinate as a CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Returns the location as a CLLocation
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    // MARK: - Distance Calculation
    
    /// Calculates distance to another station in meters
    func distance(to otherStation: SubwayStation) -> CLLocationDistance {
        return location.distance(from: otherStation.location)
    }
    
    /// Calculates distance to a coordinate in meters
    func distance(to coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
        let otherLocation = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        return location.distance(from: otherLocation)
    }
}
