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

/**
 * MapView - Main SwiftUI view for displaying the NYC subway system
 * 
 * This view provides an interactive map interface showing subway stations,
 * train positions, and route information. It integrates with SwiftData for
 * persistent storage and uses MapKit for map rendering.
 * 
 * ## Features:
 * - Interactive map centered on NYC
 * - Real-time train position markers
 * - Subway station markers with names
 * - Responsive camera positioning
 * - SwiftData integration for offline capability
 * 
 * ## Architecture:
 * - Follows SwiftUI declarative pattern
 * - Uses MVVM architecture with MapViewModel
 * - Integrates SwiftData for persistent storage
 * - Leverages MapKit for map rendering and interactions
 * 
 * ## Data Sources:
 * - Stations: SwiftData persistent storage (@Query)
 * - Train positions: Real-time via MapViewModel
 * - Map tiles: Apple Maps/MapKit
 * 
 * ## Performance Considerations:
 * - Stations loaded once from SwiftData
 * - Train positions updated periodically
 * - Map rendering optimized by MapKit
 * - Efficient marker updates using SwiftUI's diffing
 */
struct MapView: View {
    
    // MARK: - SwiftData Integration
    
    /// SwiftData model context for database operations
    @Environment(\.modelContext) var context
    
    /// Persistent subway stations loaded from SwiftData
    /// Updated automatically when database changes
    @Query private var stations: [SubwayStation]
    
    // MARK: - View Model and State
    
    /// View model managing real-time train data and MTA service interactions
    @StateObject private var viewModel: MapViewModel
    
    /// Local state for train positions (updated from view model)
    @State private var trains: [TrainPosition] = []
    
    /// State for station detail sheet presentation
    @State private var selectedStation: SubwayStation?
    @State private var showingStationDetail = false
    
    /// Station service information for detail sheet
    @State private var stationServiceInfo: StationServiceInfo?
    
    /// Camera position for map display
    /// Centered on Manhattan with appropriate zoom level for subway visibility
    @State private var camera: MapCameraPosition = .region(
        .init(
            center: .init(latitude: 40.7831, longitude: -73.9712), // Times Square area
            latitudinalMeters: 12500,  // ~7.8 miles vertical span
            longitudinalMeters: 12500  // ~7.8 miles horizontal span
        )
    )
    
    // MARK: - Initialization
    
    /**
     * Initializes the MapView with dependency injection
     * 
     * Creates a view model using the dependency container to ensure
     * proper service injection and testability.
     */
    init() {
        // Create view model using dependency container
        // Note: This is a temporary approach - in SwiftUI, we'd typically use
        // a factory pattern or pass the view model from the parent
        self._viewModel = StateObject(wrappedValue: DependencyContainer.shared.makeMapViewModel())
    }
    
    // MARK: - View Body
    
    /**
     * Main view body rendering the interactive map
     * 
     * Creates a MapKit map with:
     * - Subway station markers from SwiftData
     * - Train position markers from real-time data
     * - Interactive camera controls
     * - Full-screen display ignoring safe areas
     * 
     * ## Map Elements:
     * - Station markers: Tram icons with station names
     * - Train markers: (TODO) Dynamic train icons with route colors
     * - Route polylines: (TODO) Visual route paths
     * 
     * ## User Interactions:
     * - Pan and zoom gestures
     * - Tap to select stations/trains
     * - Pinch to zoom in/out
     * - Standard MapKit gesture recognition
     */
    var body: some View {
        Map(initialPosition: camera) {
            
            // MARK: - Station Markers
            
            // Display all subway stations from SwiftData with interactive overlays
            ForEach(stations) { station in
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
        .ignoresSafeArea(.all) // Complete full-screen map display
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
    
    /**
     * Loads station service information for the detail sheet
     * 
     * This method queries the SwiftData context for route information
     * and builds the service info using the StationServiceBuilder.
     */
    private func loadStationServiceInfo(for station: SubwayStation) {
        // TODO: Load routes from SwiftData context
        // For now, we'll use sample data
        let sampleRoutes = createSampleRoutes()
        
        stationServiceInfo = StationServiceBuilder.buildServiceInfo(
            for: station,
            routes: sampleRoutes
        )
    }
    
    /**
     * Creates sample routes for demonstration
     * 
     * In a full implementation, this would load from SwiftData
     */
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
