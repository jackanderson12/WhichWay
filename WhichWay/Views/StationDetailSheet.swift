//
//  StationDetailSheet.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/9/25.
//

import SwiftUI

struct StationDetailSheet: View {
    let station: SubwayStation
    let arrivals: [StationArrival]
    @Binding var isPresented: Bool
    var onTrainTapped: ((String) -> Void)?

    private var uptownArrivals: [StationArrival] {
        arrivals.filter { $0.direction == "N" }
    }

    private var downtownArrivals: [StationArrival] {
        arrivals.filter { $0.direction == "S" }
    }

    var body: some View {
        NavigationView {
            TimelineView(.periodic(from: .now, by: 15)) { _ in
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Station header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(station.name)
                                .font(.title2)
                                .fontWeight(.bold)

                            if !station.routeIds.isEmpty {
                                routeBadgeRow
                            }

                            if arrivals.isEmpty {
                                noArrivalsView
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // Uptown arrivals
                        if !uptownArrivals.isEmpty {
                            arrivalSection(
                                title: "Uptown/Bronx",
                                icon: "arrow.up.circle.fill",
                                color: .blue,
                                arrivals: uptownArrivals
                            )
                        }

                        // Downtown arrivals
                        if !downtownArrivals.isEmpty {
                            arrivalSection(
                                title: "Downtown/Brooklyn",
                                icon: "arrow.down.circle.fill",
                                color: .green,
                                arrivals: downtownArrivals
                            )
                        }

                        Spacer(minLength: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("Station Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Components

    private var routeBadgeRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(station.routeIds.sorted(), id: \.self) { routeId in
                    Text(routeId)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.gray))
                }
            }
        }
    }

    private var noArrivalsView: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.badge.questionmark")
                .font(.title)
                .foregroundColor(.secondary)
            Text("No upcoming arrivals")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private func arrivalSection(title: String, icon: String, color: Color, arrivals: [StationArrival]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(arrivals.count) train\(arrivals.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            let grouped = Dictionary(grouping: arrivals) { $0.routeId }
            let sortedRoutes = grouped.keys.sorted()

            ForEach(sortedRoutes, id: \.self) { routeId in
                if let routeArrivals = grouped[routeId] {
                    ForEach(routeArrivals.prefix(3)) { arrival in
                        Button {
                            onTrainTapped?(arrival.tripId)
                        } label: {
                            ArrivalRow(arrival: arrival)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    StationDetailSheet(
        station: SubwayStation(
            id: "127",
            name: "Times Sq-42 St",
            latitude: 40.755477,
            longitude: -73.987691,
            childStopIds: ["127N", "127S"],
            routeIds: ["1", "2", "3", "7", "N", "Q", "R", "W", "S"]
        ),
        arrivals: [
            StationArrival(
                id: "trip1_127N",
                routeId: "1",
                routeShortName: "1",
                routeColor: "EE352E",
                routeTextColor: "FFFFFF",
                direction: "N",
                directionLabel: "Uptown/Bronx",
                arrivalTime: Date().addingTimeInterval(120),
                tripId: "trip1"
            ),
            StationArrival(
                id: "trip2_127N",
                routeId: "2",
                routeShortName: "2",
                routeColor: "EE352E",
                routeTextColor: "FFFFFF",
                direction: "N",
                directionLabel: "Uptown/Bronx",
                arrivalTime: Date().addingTimeInterval(300),
                tripId: "trip2"
            ),
            StationArrival(
                id: "trip3_127S",
                routeId: "N",
                routeShortName: "N",
                routeColor: "FCCC0A",
                routeTextColor: "000000",
                direction: "S",
                directionLabel: "Downtown/Brooklyn",
                arrivalTime: Date().addingTimeInterval(60),
                tripId: "trip3"
            ),
        ],
        isPresented: .constant(true),
        onTrainTapped: { tripId in print("Tapped train: \(tripId)") }
    )
}
