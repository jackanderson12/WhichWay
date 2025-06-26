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
class SubwayRoutePolyline: Identifiable, Equatable {
    var id: String
    var routeId: String
    var coordinates: [CLLocationCoordinate2D]

    // computed, so it's not part of synthesis
    var polyline: MKPolyline {
        MKPolyline(coordinates: coordinates, count: coordinates.count)
    }

    init(routeId: String, coordinates: [CLLocationCoordinate2D]) {
        self.id = routeId
        self.routeId = routeId
        self.coordinates = coordinates
    }
}

extension CLLocationCoordinate2D: Codable {
    private enum CodingKeys: String, CodingKey {
        case latitude, longitude
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let lat = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let lon = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        self.init(latitude: lat, longitude: lon)
    }
}
