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

// MARK: - Line Direction Section

/**
 * LineDirectionSection - Section displaying lines for a specific direction
 * 
 * Shows a group of subway lines organized by direction with
 * route badges and line information.
 */
struct LineDirectionSection: View {
    
    let direction: LineDirection
    let lines: [StationLine]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // Direction Header
            HStack {
                Image(systemName: direction.systemImage)
                    .foregroundColor(direction == .uptown ? .blue : .green)
                    .font(.title3)
                
                Text(direction.displayName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("\(lines.count) line\(lines.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Lines Grid
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80, maximum: 120), spacing: 12)
            ], spacing: 12) {
                ForEach(lines) { line in
                    RouteBadge(line: line)
                }
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Route Badge

/**
 * RouteBadge - Visual badge representing a subway route
 * 
 * Displays the route identifier with official MTA colors and styling.
 */
struct RouteBadge: View {
    
    let line: StationLine
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(Color(hex: line.displayColor))
                    .frame(width: 40, height: 40)
                
                Text(line.routeName)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(Color(hex: line.displayTextColor))
            }
            
            Text(line.routeName)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    /**
     * Creates a Color from a hex string
     * 
     * ## Parameters:
     * - hex: Hex color string (with or without # prefix)
     * 
     * ## Example:
     * ```swift
     * let green = Color(hex: "00933C")
     * let blue = Color(hex: "#0039A6")
     * ```
     */
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
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