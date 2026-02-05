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

    /// Stations within 0.5 miles of user location (only after location is available)
    private var nearbyStations: [SubwayStation] {
        guard let userLocation = viewModel.locationManager.location else { return [] }
        return stationsWithinRadius(filteredStations, center: userLocation.coordinate, radiusMiles: 0.5)
    }

    // MARK: - Body

    var body: some View {
        Map(position: $camera) {
            // User location
            UserAnnotation()

            // Route polylines (always visible)
            ForEach(polylines) { polyline in
                if let route = routes.first(where: { $0.routeId == polyline.routeId }) {
                    MapPolyline(coordinates: polyline.coordinates)
                        .stroke(route.backgroundSwiftUIColor, lineWidth: 3)
                }
            }

            // Station markers — only shown after location is available, filtered to 0.5mi radius
            ForEach(nearbyStations) { station in
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

            // Tracked train annotation
            if let train = viewModel.trackedTrain, let coord = train.coordinate {
                Annotation("\(train.routeId) Train", coordinate: coord) {
                    ZStack {
                        Circle()
                            .fill(routeColor(for: train.routeId))
                            .frame(width: 32, height: 32)
                        Text(train.routeId)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(routeTextColor(for: train.routeId))
                        if let bearing = train.bearing {
                            Image(systemName: "location.north.fill")
                                .font(.system(size: 10))
                                .foregroundColor(routeTextColor(for: train.routeId))
                                .rotationEffect(.degrees(bearing))
                                .offset(y: -22)
                        }
                    }
                }
            }
        }
        .mapStyle(.standard(pointsOfInterest: .including([.publicTransport])))
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
                    isPresented: $viewModel.isShowingStationDetail,
                    onTrainTapped: { tripId in
                        viewModel.isShowingStationDetail = false
                        viewModel.trackTrain(tripId: tripId)
                        // Move camera to train position
                        if let train = viewModel.trackedTrain, let coord = train.coordinate {
                            camera = .region(.init(
                                center: coord,
                                latitudinalMeters: 2000,
                                longitudinalMeters: 2000
                            ))
                        }
                    }
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
            centerOnUserLocation(newLocation)
        }
        .onChange(of: routes.count) { _, _ in
            viewModel.buildRouteColorMap(from: routes)
        }
        .onDisappear {
            viewModel.stopRefresh()
        }
    }

    // MARK: - Helpers

    /// Center map on user location when first available
    private func centerOnUserLocation(_ location: CLLocation?) {
        guard !hasAutoSelectedNearest, let location else { return }
        hasAutoSelectedNearest = true
        camera = .region(.init(
            center: location.coordinate,
            latitudinalMeters: 3000,
            longitudinalMeters: 3000
        ))
    }

    /// Filter stations to those within a given radius of a center point
    private func stationsWithinRadius(_ stations: [SubwayStation], center: CLLocationCoordinate2D, radiusMiles: Double) -> [SubwayStation] {
        let radiusMeters = radiusMiles * 1609.34
        return stations.filter { $0.distance(to: center) <= radiusMeters }
    }

    /// Route background color from the color map
    private func routeColor(for routeId: String) -> Color {
        if let hex = viewModel.routeColorMap[routeId]?.color {
            return Color(hex: hex)
        }
        return .gray
    }

    /// Route text color from the color map
    private func routeTextColor(for routeId: String) -> Color {
        if let hex = viewModel.routeColorMap[routeId]?.textColor {
            return Color(hex: hex)
        }
        return .white
    }
}

#Preview {
    MapView()
}
