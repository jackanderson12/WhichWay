//
//  MapView.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/15/25.
//

import SwiftUI
import MapKit
import SwiftData

struct MapView: View {
    @Environment(\.modelContext) var context
    @Query private var stations: [SubwayStation]
    
    @StateObject var viewModel = MapViewModel()
    @State private var trains: [TrainPosition] = []
    @State private var camera: MapCameraPosition = .region(
        .init(
            center: .init(latitude: 40.7831, longitude: -73.9712),
            latitudinalMeters: 12500,
            longitudinalMeters: 12500
        )
    )
    
    var body: some View {
        Map(initialPosition: camera) {
            ForEach(stations) { station in
                Marker(
                    station.name,
                    systemImage: "tram.fill",
                    coordinate: station.coordinate
                )
            }
        }
        .ignoresSafeArea()
        .task {
            trains = viewModel.trainPositions
        }
    }
}


#Preview {
    MapView()
}
