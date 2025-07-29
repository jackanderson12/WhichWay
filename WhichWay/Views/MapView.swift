//
//  MapView.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/15/25.
//

import SwiftUI
import MapKit
import SwiftData

// MARK: - Map View

/// Main map view displaying NYC subway stations and trains
struct MapView: View {
    
    // MARK: - SwiftData Integration
    
    @Environment(\.modelContext) var context
    @Query private var stations: [SubwayStation]
    
    // MARK: - View Model and State
    
    @StateObject private var viewModel: MapViewModel
    @State private var trains: [TrainPosition] = []
    @State private var selectedStation: SubwayStation?
    @State private var showingStationDetail = false
    @State private var stationServiceInfo: StationServiceInfo?
    @State private var camera: MapCameraPosition = .region(
        .init(
            center: .init(latitude: 40.7831, longitude: -73.9712), // Times Square
            latitudinalMeters: 12500,
            longitudinalMeters: 12500
        )
    )
    @State private var searchText = ""
    
    // MARK: - Initialization
    init() {
        // Create view model using dependency container
        self._viewModel = StateObject(wrappedValue: DependencyContainer.shared.makeMapViewModel())
    }
    
    // MARK: - Computed Properties
    
    /// Filtered stations based on search text
    private var filteredStations: [SubwayStation] {
        SearchBarView.filteredStations(stations, searchText: searchText)
    }
    
    // MARK: - View Body
    var body: some View {
        Map(initialPosition: camera) {
            
            // MARK: - Station Markers
            ForEach(filteredStations) { station in
                Annotation(
                    station.name,
                    coordinate: station.coordinate
                ) {
                    Button(action: {
                        selectedStation = station
                        loadStationServiceInfo(for: station)
                        showingStationDetail = true
                    }) {
                        Image(systemName: "tram.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // TODO: Add train position markers
            // ForEach(trains) { train in
            //     Marker(
            //         train.displayName,
            //         systemImage: "train.side.front.car",
            //         coordinate: train.coordinate
            //     )
            // }
            
            // TODO: Add route polylines
            // ForEach(routes) { route in
            //     MapPolyline(route.polyline)
            //         .stroke(route.color, lineWidth: 3)
            // }
        }
        .ignoresSafeArea(.all)
        .edgesIgnoringSafeArea(.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .overlay(
            // MARK: - Search Bar Overlay
            
            SearchBarView(searchText: $searchText)
                .allowsHitTesting(true)
        )
        .sheet(isPresented: $showingStationDetail) {
            if let serviceInfo = stationServiceInfo {
                StationDetailSheet(
                    serviceInfo: serviceInfo,
                    isPresented: $showingStationDetail
                )
            }
        }
        .task {
            // Update local train state when view model changes
            trains = viewModel.trainPositions
        }
    }
    
    // MARK: - Helper Methods
    
    /// Loads station service info for detail sheet
    private func loadStationServiceInfo(for station: SubwayStation) {
        // TODO: Load routes from SwiftData context
        // For now, we'll use sample data
        let sampleRoutes = createSampleRoutes()
        
        stationServiceInfo = StationServiceBuilder.buildServiceInfo(
            for: station,
            routes: sampleRoutes
        )
    }
    
    /// Creates sample routes for demonstration
    private func createSampleRoutes() -> [SubwayRoute] {
        return [
            SubwayRoute(
                routeId: "1",
                routeShortName: "1",
                routeLongName: "Broadway - 7 Avenue Local",
                routeDescription: "Local service",
                routeColor: "EE352E",
                routeTextColor: "FFFFFF"
            ),
            SubwayRoute(
                routeId: "2",
                routeShortName: "2",
                routeLongName: "7 Avenue Express",
                routeDescription: "Express service",
                routeColor: "EE352E",
                routeTextColor: "FFFFFF"
            ),
            SubwayRoute(
                routeId: "4",
                routeShortName: "4",
                routeLongName: "Lexington Avenue Express",
                routeDescription: "Express service",
                routeColor: "00933C",
                routeTextColor: "FFFFFF"
            ),
            SubwayRoute(
                routeId: "5",
                routeShortName: "5",
                routeLongName: "Lexington Avenue Express",
                routeDescription: "Express service",
                routeColor: "00933C",
                routeTextColor: "FFFFFF"
            ),
            SubwayRoute(
                routeId: "6",
                routeShortName: "6",
                routeLongName: "Lexington Avenue Local",
                routeDescription: "Local service",
                routeColor: "00933C",
                routeTextColor: "FFFFFF"
            ),
            SubwayRoute(
                routeId: "N",
                routeShortName: "N",
                routeLongName: "Broadway Local",
                routeDescription: "Local service",
                routeColor: "FCCC0A",
                routeTextColor: "000000"
            ),
            SubwayRoute(
                routeId: "Q",
                routeShortName: "Q",
                routeLongName: "Broadway Express",
                routeDescription: "Express service",
                routeColor: "FCCC0A",
                routeTextColor: "000000"
            ),
            SubwayRoute(
                routeId: "R",
                routeShortName: "R",
                routeLongName: "Broadway Local",
                routeDescription: "Local service",
                routeColor: "FCCC0A",
                routeTextColor: "000000"
            ),
            SubwayRoute(
                routeId: "W",
                routeShortName: "W",
                routeLongName: "Broadway Local",
                routeDescription: "Weekday service",
                routeColor: "FCCC0A",
                routeTextColor: "000000"
            )
        ]
    }
}


#Preview {
    MapView()
}
