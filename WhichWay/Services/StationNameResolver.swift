//
//  StationNameResolver.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/9/25.
//

import Foundation

// MARK: - Station Name Resolver

/**
 * StationNameResolver - Handles mapping from GTFS stop IDs to station information
 * 
 * This class provides a centralized service for resolving station names and
 * coordinates from GTFS stop IDs, enabling consistent station information
 * display throughout the app.
 * 
 * ## Key Responsibilities:
 * - Map stop IDs to human-readable station names
 * - Provide station coordinates for mapping
 * - Handle NYC-specific stop ID formats
 * - Cache station information for performance
 * 
 * ## Data Sources:
 * - GTFS stops.txt file for comprehensive station data
 * - Hardcoded NYC subway station mappings
 * - Future: SwiftData cache for offline capability
 */
class StationNameResolver: StationNameResolverProtocol {
    
    // MARK: - Static Station Data
    
    /**
     * Hardcoded NYC subway station mappings
     * 
     * This provides a fallback for common NYC subway stations when
     * GTFS data is not available. In a production app, this would be
     * loaded from GTFS stops.txt or a local database.
     */
    private static let nycSubwayStations: [String: StationInfo] = [
        "127": StationInfo(
            name: "Times Sq-42 St",
            latitude: 40.755477,
            longitude: -73.987691
        ),
        "631": StationInfo(
            name: "Grand Central-42 St",
            latitude: 40.751776,
            longitude: -73.976848
        ),
        "635": StationInfo(
            name: "14 St-Union Sq",
            latitude: 40.735736,
            longitude: -73.990568
        ),
        "142": StationInfo(
            name: "Wall St",
            latitude: 40.707557,
            longitude: -73.006924
        ),
        "417": StationInfo(
            name: "Brooklyn Bridge-City Hall",
            latitude: 40.713065,
            longitude: -74.006094
        ),
        "621": StationInfo(
            name: "Lexington Ave/59 St",
            latitude: 40.762526,
            longitude: -73.967967
        ),
        "232": StationInfo(
            name: "125 St",
            latitude: 40.804138,
            longitude: -73.937594
        ),
        "619": StationInfo(
            name: "Lexington Ave/53 St",
            latitude: 40.757552,
            longitude: -73.969055
        ),
        "626": StationInfo(
            name: "86 St",
            latitude: 40.779492,
            longitude: -73.955589
        ),
        "629": StationInfo(
            name: "68 St-Hunter College",
            latitude: 40.768141,
            longitude: -73.963900
        )
    ]
    
    // MARK: - Properties
    
    /// Cache of resolved station names for performance
    private var nameCache: [String: String] = [:]
    
    /// Cache of resolved coordinates for performance
    private var coordinateCache: [String: (latitude: Double, longitude: Double)] = [:]
    
    // MARK: - Initialization
    
    /**
     * Initializes the resolver with static data
     * 
     * Future versions could accept a data source for loading
     * station information from GTFS files or SwiftData.
     */
    init() {
        // Pre-populate caches with static data
        for (stopId, stationInfo) in Self.nycSubwayStations {
            nameCache[stopId] = stationInfo.name
            coordinateCache[stopId] = (stationInfo.latitude, stationInfo.longitude)
        }
    }
    
    // MARK: - StationNameResolverProtocol Implementation
    
    /**
     * Resolves a human-readable name for a given stop ID
     * 
     * This method handles NYC-specific stop ID formats where direction
     * suffixes (N/S) are appended to the base station ID.
     * 
     * ## Parameters:
     * - stopId: GTFS stop ID (e.g., "127N", "631S")
     * 
     * ## Returns:
     * Human-readable station name or fallback if not found
     * 
     * ## Example:
     * ```swift
     * resolver.resolveName(for: "127N") // Returns "Times Sq-42 St"
     * resolver.resolveName(for: "999X") // Returns "Station 999"
     * ```
     */
    func resolveName(for stopId: String) -> String {
        // Check cache first
        if let cachedName = nameCache[stopId] {
            return cachedName
        }
        
        // Remove direction suffix for lookup
        let cleanStopId = cleanStopId(stopId)
        
        // Check cache with clean ID
        if let cachedName = nameCache[cleanStopId] {
            nameCache[stopId] = cachedName // Cache with original ID
            return cachedName
        }
        
        // Look up in static data
        if let stationInfo = Self.nycSubwayStations[cleanStopId] {
            let name = stationInfo.name
            nameCache[stopId] = name
            nameCache[cleanStopId] = name
            return name
        }
        
        // Fallback to generic name
        let fallbackName = "Station \(cleanStopId)"
        nameCache[stopId] = fallbackName
        return fallbackName
    }
    
    /**
     * Resolves coordinates for a given stop ID
     * 
     * Returns the latitude and longitude coordinates for a station,
     * enabling map positioning and distance calculations.
     * 
     * ## Parameters:
     * - stopId: GTFS stop ID (e.g., "127N", "631S")
     * 
     * ## Returns:
     * Tuple of (latitude, longitude) or nil if not found
     * 
     * ## Example:
     * ```swift
     * resolver.resolveCoordinate(for: "127N") // Returns (40.755477, -73.987691)
     * resolver.resolveCoordinate(for: "999X") // Returns nil
     * ```
     */
    func resolveCoordinate(for stopId: String) -> (latitude: Double, longitude: Double)? {
        // Check cache first
        if let cachedCoordinate = coordinateCache[stopId] {
            return cachedCoordinate
        }
        
        // Remove direction suffix for lookup
        let cleanStopId = cleanStopId(stopId)
        
        // Check cache with clean ID
        if let cachedCoordinate = coordinateCache[cleanStopId] {
            coordinateCache[stopId] = cachedCoordinate // Cache with original ID
            return cachedCoordinate
        }
        
        // Look up in static data
        if let stationInfo = Self.nycSubwayStations[cleanStopId] {
            let coordinate = (stationInfo.latitude, stationInfo.longitude)
            coordinateCache[stopId] = coordinate
            coordinateCache[cleanStopId] = coordinate
            return coordinate
        }
        
        // Not found
        return nil
    }
    
    // MARK: - Private Helper Methods
    
    /**
     * Removes direction suffixes from stop IDs
     * 
     * NYC stop IDs often have direction suffixes (N/S) that need to be
     * removed for station lookup.
     * 
     * ## Parameters:
     * - stopId: Original stop ID with potential suffix
     * 
     * ## Returns:
     * Clean stop ID without direction suffix
     * 
     * ## Example:
     * ```swift
     * cleanStopId("127N") // Returns "127"
     * cleanStopId("631S") // Returns "631"
     * cleanStopId("999")  // Returns "999"
     * ```
     */
    private func cleanStopId(_ stopId: String) -> String {
        return stopId.replacingOccurrences(
            of: "[NS]$",
            with: "",
            options: .regularExpression
        )
    }
    
    // MARK: - Public Utility Methods
    
    /**
     * Adds a custom station mapping
     * 
     * Allows runtime addition of station information, useful for
     * testing or handling new stations not in the static data.
     * 
     * ## Parameters:
     * - stopId: Base stop ID (without direction suffix)
     * - name: Human-readable station name
     * - coordinate: Station coordinates
     */
    func addStationMapping(
        stopId: String,
        name: String,
        coordinate: (latitude: Double, longitude: Double)
    ) {
        nameCache[stopId] = name
        coordinateCache[stopId] = coordinate
    }
    
    /**
     * Clears all cached data
     * 
     * Useful for testing or when refreshing station data from
     * external sources.
     */
    func clearCache() {
        nameCache.removeAll()
        coordinateCache.removeAll()
        
        // Re-populate with static data
        for (stopId, stationInfo) in Self.nycSubwayStations {
            nameCache[stopId] = stationInfo.name
            coordinateCache[stopId] = (stationInfo.latitude, stationInfo.longitude)
        }
    }
}

// MARK: - Supporting Types

/**
 * Internal structure for station information
 * 
 * Used for static data storage and caching of station details.
 */
private struct StationInfo {
    let name: String
    let latitude: Double
    let longitude: Double
}