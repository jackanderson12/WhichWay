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
            // Map each entity with a vehicle position into our TrainPosition struct
            let newPositions = feed.entity.compactMap { entity -> TrainPosition? in
                let vehicle = entity.vehicle
                let lat = vehicle.position.latitude
                let lon = vehicle.position.longitude
                return TrainPosition(
                    id: entity.id,
                    coordinate: CLLocationCoordinate2D(
                        latitude: CLLocationDegrees(lat),
                        longitude: CLLocationDegrees(lon)
                    )
                )
            }
            self.trainPositions = newPositions
        } catch {
            print("Error fetching train positions:", error)
        }
    }
}
