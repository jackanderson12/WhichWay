//
//  StationDetailSheet.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/9/25.
//

import SwiftUI

// MARK: - Station Detail Sheet

/**
 * StationDetailSheet - Half sheet view displaying station information
 * 
 * This view presents detailed information about a subway station,
 * including the lines that serve it, organized by direction.
 * 
 * ## Features:
 * - Station name and location
 * - Lines categorized by direction (Uptown/Downtown)
 * - Route badges with official MTA colors
 * - Smooth animations and transitions
 * - Native iOS half sheet presentation
 * 
 * ## Usage:
 * Presented as a sheet when a station annotation is tapped on the map.
 * Uses SwiftUI's native sheet presentation with detents for half-screen display.
 */
struct StationDetailSheet: View {
    
    // MARK: - Properties
    
    let serviceInfo: StationServiceInfo
    @Binding var isPresented: Bool
    
    // MARK: - View Body
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // MARK: - Station Header
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(serviceInfo.station.name)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("\(serviceInfo.totalLines) line\(serviceInfo.totalLines == 1 ? "" : "s") serving this station")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // MARK: - Uptown/Bronx Lines
                    
                    if serviceInfo.hasUptownService {
                        LineDirectionSection(
                            direction: .uptown,
                            lines: serviceInfo.uptownLines
                        )
                    }
                    
                    // MARK: - Downtown/Brooklyn Lines
                    
                    if serviceInfo.hasDowntownService {
                        LineDirectionSection(
                            direction: .downtown,
                            lines: serviceInfo.downtownLines
                        )
                    }
                    
                    // MARK: - Station Information
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "location.circle.fill")
                                .foregroundColor(.blue)
                            Text("Station Location")
                                .font(.headline)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Latitude: \(serviceInfo.station.latitude, specifier: "%.6f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Longitude: \(serviceInfo.station.longitude, specifier: "%.6f")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 20)
                    
                    Spacer(minLength: 50)
                }
                .padding()
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
}

// MARK: - Preview

#Preview {
    StationDetailSheet(
        serviceInfo: StationServiceInfo(
            station: SubwayStation(
                id: "127",
                name: "Times Sq-42 St",
                latitude: 40.755477,
                longitude: -73.987691
            ),
            uptownLines: [
                StationLine(
                    routeId: "1",
                    routeName: "1",
                    routeColor: "EE352E",
                    routeTextColor: "FFFFFF",
                    direction: .uptown,
                    longName: "Broadway - 7 Avenue Local",
                    description: "Local service"
                ),
                StationLine(
                    routeId: "2",
                    routeName: "2",
                    routeColor: "EE352E",
                    routeTextColor: "FFFFFF",
                    direction: .uptown,
                    longName: "7 Avenue Express",
                    description: "Express service"
                ),
                StationLine(
                    routeId: "3",
                    routeName: "3",
                    routeColor: "EE352E",
                    routeTextColor: "FFFFFF",
                    direction: .uptown,
                    longName: "7 Avenue Express",
                    description: "Express service"
                )
            ],
            downtownLines: [
                StationLine(
                    routeId: "N",
                    routeName: "N",
                    routeColor: "FCCC0A",
                    routeTextColor: "000000",
                    direction: .downtown,
                    longName: "Broadway Local",
                    description: "Local service"
                ),
                StationLine(
                    routeId: "Q",
                    routeName: "Q",
                    routeColor: "FCCC0A",
                    routeTextColor: "000000",
                    direction: .downtown,
                    longName: "Broadway Express",
                    description: "Express service"
                ),
                StationLine(
                    routeId: "R",
                    routeName: "R",
                    routeColor: "FCCC0A",
                    routeTextColor: "000000",
                    direction: .downtown,
                    longName: "Broadway Local",
                    description: "Local service"
                ),
                StationLine(
                    routeId: "W",
                    routeName: "W",
                    routeColor: "FCCC0A",
                    routeTextColor: "000000",
                    direction: .downtown,
                    longName: "Broadway Local",
                    description: "Weekday service"
                )
            ]
        ),
        isPresented: .constant(true)
    )
}
