//
//  Routes.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/24/25.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Subway Route Models

/**
 * SubwayRoute - SwiftData model for NYC subway route information
 * 
 * This model stores persistent metadata about subway routes including
 * identifiers, names, descriptions, and visual styling information.
 * It represents the static information that doesn't change frequently.
 * 
 * ## Features:
 * - Complete GTFS route information storage
 * - SwiftUI Color integration for route styling
 * - Persistent storage in SwiftData
 * - Route identification and organization
 * 
 * ## Data Source:
 * Route data is derived from MTA's GTFS routes.txt file, which contains
 * comprehensive information about each subway route including official
 * colors, names, and descriptions.
 * 
 * ## Usage:
 * Routes are loaded once from GTFS data and stored persistently.
 * They provide styling information for map display and user interface
 * elements throughout the app.
 * 
 * ## Visual Integration:
 * The color properties enable consistent visual representation across
 * the app, matching official MTA branding and user expectations.
 */
@Model
final class SubwayRoute {
    
    // MARK: - Stored Properties
    
    /// Unique route identifier from GTFS (e.g., "4", "6", "L", "N")
    var routeId: String
    
    /// Agency identifier (typically "MTA NYCT" for NYC subway)
    var agencyId: String
    
    /// Short route name for display (e.g., "4", "6", "L")
    /// This is what users see on train signs and maps
    var routeShortName: String
    
    /// Full descriptive route name (e.g., "Lexington Avenue Express")
    var routeLongName: String
    
    /// Detailed route description including endpoints and service pattern
    var routeDescription: String
    
    /// Official MTA URL for route information and updates
    var routeUrl: String
    
    /// Official route color in hex format (e.g., "00933C" for 4/5/6 green)
    /// Optional because some routes may not have assigned colors
    var routeColor: String?
    
    /// Text color for route displays (typically white or black)
    /// Ensures proper contrast with the route background color
    var routeTextColor: String?
    
    // MARK: - Initialization
    
    /**
     * Creates a new subway route instance
     * 
     * ## Parameters:
     * - routeId: Unique identifier for the route
     * - agencyId: Operating agency identifier
     * - routeShortName: Short name for UI display
     * - routeLongName: Full descriptive name
     * - routeDescription: Detailed route description
     * - routeUrl: Official route information URL
     * - routeColor: Optional hex color code (without #)
     * - routeTextColor: Optional text color for contrast
     * 
     * ## Example:
     * ```swift
     * let route = SubwayRoute(
     *     routeId: "4",
     *     agencyId: "MTA NYCT",
     *     routeShortName: "4",
     *     routeLongName: "Lexington Avenue Express",
     *     routeDescription: "Times Square to Woodlawn/Utica Avenue",
     *     routeUrl: "https://www.mta.info/nyct/service/4line.htm",
     *     routeColor: "00933C",
     *     routeTextColor: "FFFFFF"
     * )
     * ```
     */
    init(
        routeId: String,
        agencyId: String,
        routeShortName: String,
        routeLongName: String,
        routeDescription: String,
        routeUrl: String,
        routeColor: String?,
        routeTextColor: String?
    ) {
        self.routeId = routeId
        self.agencyId = agencyId
        self.routeShortName = routeShortName
        self.routeLongName = routeLongName
        self.routeDescription = routeDescription
        self.routeUrl = routeUrl
        self.routeColor = routeColor
        self.routeTextColor = routeTextColor
    }
    
    // Convenience initializer for simplified route creation
    convenience init(
        routeId: String,
        routeShortName: String,
        routeLongName: String,
        routeDescription: String,
        routeColor: String?,
        routeTextColor: String?
    ) {
        self.init(
            routeId: routeId,
            agencyId: "MTA NYCT",
            routeShortName: routeShortName,
            routeLongName: routeLongName,
            routeDescription: routeDescription,
            routeUrl: "https://www.mta.info/nyct/service/\(routeId)line.htm",
            routeColor: routeColor,
            routeTextColor: routeTextColor
        )
    }
    
    // MARK: - Computed Properties
    
    /**
     * SwiftUI Color for route background
     * 
     * Converts the stored hex color string to a SwiftUI Color for
     * use in UI elements like route badges and map styling.
     * 
     * ## Returns:
     * SwiftUI Color from hex string, or gray if no color is defined
     */
    var backgroundSwiftUIColor: Color {
        guard let colorString = routeColor else {
            return Color.gray
        }
        return Color(hex: colorString)
    }
    
    /**
     * SwiftUI Color for route text
     * 
     * Converts the stored hex text color string to a SwiftUI Color
     * for proper contrast with the background color.
     * 
     * ## Returns:
     * SwiftUI Color from hex string, or white if no color is defined
     */
    var textSwiftUIColor: Color {
        guard let colorString = routeTextColor else {
            return Color.white
        }
        return Color(hex: colorString)
    }
}

