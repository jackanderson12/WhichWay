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

    // MARK: - SwiftData

    @Environment(\.modelContext) var context
    @Query private var stations: [SubwayStation]
    @Query private var routes: [SubwayRoute]
    @Query private var polylines: [SubwayRoutePolyline]

    // MARK: - State

    @State private var viewModel = DependencyContainer.shared.makeMapViewModel()
    @State private var camera: MapCameraPosition = .region(
        .init(
            center: .init(latitude: 40.7831, longitude: -73.9712),
            latitudinalMeters: 12500,
            longitudinalMeters: 12500
        )
    )
    @State private var searchText = ""
    @State private var hasAutoSelectedNearest = false

    // MARK: - Computed

    private var filteredStations: [SubwayStation] {
        SearchBarView.filteredStations(stations, searchText: searchText)
    }

    // MARK: - Body

    var body: some View {
        Map(position: $camera) {
            // User location
            UserAnnotation()

            // Station markers
            ForEach(filteredStations) { station in
                Annotation(
                    station.name,
                    coordinate: station.coordinate
                ) {
                    Button {
                        viewModel.selectStation(station)
                    } label: {
                        Image(systemName: "tram.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .background(Color.white)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.blue, lineWidth: 2))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            // Route polylines
            ForEach(polylines) { polyline in
                if let route = routes.first(where: { $0.routeId == polyline.routeId }) {
                    MapPolyline(coordinates: polyline.coordinates)
                        .stroke(route.backgroundSwiftUIColor, lineWidth: 3)
                }
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
            MapScaleView()
        }
        .ignoresSafeArea(.all)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .overlay(
            SearchBarView(searchText: $searchText)
                .allowsHitTesting(true)
        )
        .sheet(isPresented: $viewModel.isShowingStationDetail) {
            if let station = viewModel.selectedStation {
                StationDetailSheet(
                    station: station,
                    arrivals: viewModel.stationArrivals,
                    isPresented: $viewModel.isShowingStationDetail
                )
            }
        }
        .task {
            // Build route color map from SwiftData routes
            viewModel.buildRouteColorMap(from: routes)

            // Request location permission
            viewModel.requestLocationPermission()

            // Start fetching all feeds
            viewModel.startFeedRefreshLoop()
        }
        .onChange(of: viewModel.locationManager.location) { _, newLocation in
            autoSelectNearestStation(userLocation: newLocation)
        }
        .onChange(of: viewModel.trainPositions.count) { _, _ in
            // After first feed load, try to select nearest station
            autoSelectNearestStation(userLocation: viewModel.locationManager.location)
        }
        .onChange(of: routes.count) { _, _ in
            viewModel.buildRouteColorMap(from: routes)
        }
        .onDisappear {
            viewModel.stopRefresh()
        }
    }

    // MARK: - Auto-select Nearest Station

    private func autoSelectNearestStation(userLocation: CLLocation?) {
        guard !hasAutoSelectedNearest,
              let userLocation = userLocation,
              !stations.isEmpty,
              !viewModel.trainPositions.isEmpty else { return }

        hasAutoSelectedNearest = true

        // Center map on user location
        camera = .region(.init(
            center: userLocation.coordinate,
            latitudinalMeters: 3000,
            longitudinalMeters: 3000
        ))

        // Select nearest station
        let nearest = viewModel.nearestStations(from: stations, count: 1)
        if let station = nearest.first {
            viewModel.selectStation(station)
        }
    }
}

#Preview {
    MapView()
}
