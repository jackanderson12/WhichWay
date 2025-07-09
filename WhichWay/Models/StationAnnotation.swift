//
//  StationAnnotation.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/9/25.
//

import Foundation
import MapKit
import SwiftData

// MARK: - Station Annotation Model

/**
 * StationAnnotation - MapKit annotation for subway stations
 * 
 * This model represents a subway station for MapKit display, including
 * the station information and the transit lines that serve it.
 * 
 * ## Features:
 * - MapKit annotation support
 * - Station information display
 * - Transit line categorization by direction
 * - Route color and styling information
 * 
 * ## Usage:
 * Used by MapView to display subway stations as interactive annotations
 * that can be tapped to show detailed station information.
 */
class StationAnnotation: NSObject, MKAnnotation {
    
    // MARK: - MKAnnotation Properties
    
    let coordinate: CLLocationCoordinate2D
    let title: String?
    let subtitle: String?
    
    // MARK: - Station Properties
    
    let station: SubwayStation
    let servingLines: [StationLine]
    
    // MARK: - Initialization
    
    init(station: SubwayStation, servingLines: [StationLine]) {
        self.station = station
        self.servingLines = servingLines
        self.coordinate = station.coordinate
        self.title = station.name
        self.subtitle = servingLines.map(\.routeId).joined(separator: ", ")
        super.init()
    }
}

// MARK: - Station Line Model

/**
 * StationLine - Represents a subway line serving a station
 * 
 * Contains information about a specific subway line at a station,
 * including route details, direction, and visual styling.
 */
struct StationLine: Identifiable, Hashable {
    let id = UUID()
    let routeId: String
    let routeName: String
    let routeColor: String
    let routeTextColor: String
    let direction: LineDirection
    let longName: String
    let description: String
    
    // MARK: - Computed Properties
    
    var displayColor: String {
        return routeColor.isEmpty ? "808080" : routeColor
    }
    
    var displayTextColor: String {
        return routeTextColor.isEmpty ? "FFFFFF" : routeTextColor
    }
}

// MARK: - Line Direction Enum

/**
 * LineDirection - Represents the direction of subway lines
 * 
 * Categorizes subway lines into two main directional groups
 * for better user understanding.
 */
enum LineDirection: String, CaseIterable {
    case uptown = "Uptown/Bronx"
    case downtown = "Downtown/Brooklyn"
    
    var displayName: String {
        return rawValue
    }
    
    var systemImage: String {
        switch self {
        case .uptown:
            return "arrow.up.circle.fill"
        case .downtown:
            return "arrow.down.circle.fill"
        }
    }
}

// MARK: - Station Service Information

/**
 * StationServiceInfo - Aggregated information about station services
 * 
 * Groups station lines by direction and provides organized data
 * for the station detail view.
 */
struct StationServiceInfo {
    let station: SubwayStation
    let uptownLines: [StationLine]
    let downtownLines: [StationLine]
    
    var totalLines: Int {
        return uptownLines.count + downtownLines.count
    }
    
    var hasUptownService: Bool {
        return !uptownLines.isEmpty
    }
    
    var hasDowntownService: Bool {
        return !downtownLines.isEmpty
    }
    
    var allLines: [StationLine] {
        return uptownLines + downtownLines
    }
}

// MARK: - Station Service Builder

/**
 * StationServiceBuilder - Utility for building station service information
 * 
 * Processes GTFS data to determine which lines serve which stations
 * and categorizes them by direction.
 */
struct StationServiceBuilder {
    
    /**
     * Builds station service information from GTFS data
     * 
     * ## Parameters:
     * - station: The subway station
     * - routes: Available subway routes
     * - trips: Trip information linking routes to stations
     * - stopTimes: Stop time information
     * 
     * ## Returns:
     * StationServiceInfo with organized line information
     */
    static func buildServiceInfo(
        for station: SubwayStation,
        routes: [SubwayRoute],
        trips: [String: String] = [:], // tripId -> routeId mapping
        stopTimes: [String: [String]] = [:] // stopId -> [tripId] mapping
    ) -> StationServiceInfo {
        
        // For now, we'll use a simplified approach based on common NYC subway knowledge
        // In a full implementation, this would parse the GTFS trip and stop_times data
        let stationLines = generateStationLines(for: station, routes: routes)
        
        // Categorize lines by direction
        let uptownLines = stationLines.filter { $0.direction == .uptown }
        let downtownLines = stationLines.filter { $0.direction == .downtown }
        
        return StationServiceInfo(
            station: station,
            uptownLines: uptownLines,
            downtownLines: downtownLines
        )
    }
    
    /**
     * Generates station lines based on station location and route information
     * 
     * This is a simplified implementation. In a full app, this would
     * parse the GTFS stop_times.txt and trips.txt files to determine
     * which routes actually serve each station.
     */
    private static func generateStationLines(
        for station: SubwayStation,
        routes: [SubwayRoute]
    ) -> [StationLine] {
        
        // For demonstration, we'll assign some common lines based on station names
        // In reality, this would come from parsing GTFS data
        let stationName = station.name.lowercased()
        var stationLines: [StationLine] = []
        
        // Generate lines for major stations (simplified mapping)
        // This is a temporary approach - in production, this would come from GTFS stop_times.txt
        if stationName.contains("times sq") || stationName.contains("42") {
            let timesSquareRoutes = ["1", "2", "3", "7", "N", "Q", "R", "W", "S"]
            stationLines = createLinesFromRoutes(timesSquareRoutes, routes: routes)
        } else if stationName.contains("union") || stationName.contains("14") {
            let unionSquareRoutes = ["4", "5", "6", "L", "N", "Q", "R", "W"]
            stationLines = createLinesFromRoutes(unionSquareRoutes, routes: routes)
        } else if stationName.contains("grand central") {
            let grandCentralRoutes = ["4", "5", "6", "7", "S"]
            stationLines = createLinesFromRoutes(grandCentralRoutes, routes: routes)
        } else if stationName.contains("herald sq") || stationName.contains("34") {
            let heraldSquareRoutes = ["B", "D", "F", "M", "N", "Q", "R", "W"]
            stationLines = createLinesFromRoutes(heraldSquareRoutes, routes: routes)
        } else if stationName.contains("fulton") {
            let fultonRoutes = ["A", "C", "J", "Z", "2", "3", "4", "5"]
            stationLines = createLinesFromRoutes(fultonRoutes, routes: routes)
        } else if stationName.contains("atlantic") {
            let atlanticRoutes = ["B", "D", "N", "Q", "R", "W", "2", "3", "4", "5"]
            stationLines = createLinesFromRoutes(atlanticRoutes, routes: routes)
        } else {
            // For other stations, assign a random but reasonable set of routes
            // This prevents empty stations while we develop proper GTFS parsing
            let commonRouteGroups = [
                ["1", "2", "3"], // Red line group
                ["4", "5", "6"], // Green line group  
                ["N", "Q", "R", "W"], // Yellow line group
                ["A", "C", "E"], // Blue line group
                ["B", "D", "F", "M"], // Orange line group
                ["G"], // Light Green
                ["J", "Z"], // Brown line group
                ["L"] // Gray line
            ]
            
            // Use station name hash to consistently assign routes
            let hashValue = abs(stationName.hashValue)
            let selectedGroup = commonRouteGroups[hashValue % commonRouteGroups.count]
            stationLines = createLinesFromRoutes(selectedGroup, routes: routes)
        }
        
        return stationLines
    }
    
    /**
     * Creates station lines from route IDs
     */
    private static func createLinesFromRoutes(
        _ routeIds: [String],
        routes: [SubwayRoute]
    ) -> [StationLine] {
        return routeIds.compactMap { routeId in
            guard let route = routes.first(where: { $0.routeId == routeId }) else {
                return nil
            }
            
            return StationLine(
                routeId: route.routeId,
                routeName: route.routeShortName,
                routeColor: route.routeColor ?? "808080",
                routeTextColor: route.routeTextColor ?? "FFFFFF",
                direction: determineDirection(for: route),
                longName: route.routeLongName,
                description: route.routeDescription
            )
        }
    }
    
    /**
     * Determines direction based on route information
     * 
     * This is a simplified implementation. In reality, each route
     * serves both directions, but we'll alternate for demonstration.
     */
    private static func determineDirection(for route: SubwayRoute) -> LineDirection {
        // Simplified logic - in reality, each route serves both directions
        // We'll alternate for demonstration purposes
        let hash = route.routeId.hash
        return hash % 2 == 0 ? .uptown : .downtown
    }
}