//
//  MapViewModel.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/15/25.
//

import Foundation
import SwiftUI
import SwiftProtobuf
import MapKit

// MARK: - Map View Model

/**
 * MapViewModel - ObservableObject that manages subway data for the map interface
 * 
 * This view model serves as the data layer between the UI and the MTA service,
 * processing real-time train data and presenting it in a format suitable for
 * map visualization and user interaction.
 * 
 * ## Architecture:
 * - Follows MVVM pattern with reactive data binding
 * - Uses @Published properties for automatic UI updates
 * - Handles async data fetching and error management
 * - Transforms raw GTFS data into user-friendly models
 * - Supports dependency injection for testability
 * 
 * ## Key Responsibilities:
 * - Fetch and process real-time train positions
 * - Manage periodic data updates
 * - Handle network errors gracefully
 * - Provide processed data to map views
 * - Manage UI state (loading, error handling)
 * 
 * ## Data Flow:
 * MTAService → GTFSDataProcessor → MapViewModel → MapView
 * 
 * ## Usage:
 * Instantiate once per map view and let SwiftUI handle the lifecycle.
 * The view model automatically starts fetching data on initialization.
 */
class MapViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Array of current train positions for map display
    /// Updated automatically when new GTFS-RT data arrives
    @Published var trainPositions: [TrainPosition] = []
    
    /// Loading state for UI feedback
    @Published var isLoading = false
    
    /// Error state for user feedback
    @Published var error: Error?
    
    // MARK: - Private Properties
    
    /// Service instance for MTA data operations
    private let mtaService: MTAServiceProtocol
    
    /// Data processor for GTFS-RT transformation
    private let dataProcessor: GTFSDataProcessorProtocol

    // MARK: - Initialization
    
    /**
     * Initializes the view model with dependency injection
     * 
     * ## Parameters:
     * - mtaService: Service for MTA data operations
     * - dataProcessor: Processor for GTFS-RT data transformation
     * 
     * ## Example:
     * ```swift
     * // Production usage
     * let viewModel = MapViewModel()
     * 
     * // Testing usage
     * let mockService = MockMTAService()
     * let mockProcessor = MockGTFSDataProcessor()
     * let viewModel = MapViewModel(mtaService: mockService, dataProcessor: mockProcessor)
     * ```
     */
    init(
        mtaService: MTAServiceProtocol = MTAService(),
        dataProcessor: GTFSDataProcessorProtocol = GTFSDataProcessor()
    ) {
        self.mtaService = mtaService
        self.dataProcessor = dataProcessor
        
        // Start data fetching
        Task {
            await fetchBaseData()
            await fetchTrainPositions()
        }
    }
    
    // MARK: - Data Fetching Methods
    
    /**
     * Fetches base subway system data from MTA
     * 
     * Downloads and processes static GTFS data including station locations,
     * route information, and system topology. This data is updated weekly
     * and provides the foundation for real-time overlays.
     * 
     * ## Implementation Notes:
     * - Runs on main actor for UI safety
     * - Uses try? to handle errors gracefully without crashing
     * - Should be called periodically to maintain data freshness
     * 
     * ## Future Enhancements:
     * - Add error handling and user feedback
     * - Implement caching to reduce bandwidth usage
     * - Add progress indicators for large downloads
     */
    @MainActor
    func fetchBaseData() async {
        do {
            try await mtaService.fetchBaseData()
        } catch {
            self.error = error
        }
    }

    /**
     * Fetches and processes real-time train positions from GTFS-RT feed
     * 
     * This method performs the core data transformation from raw GTFS-RT
     * protobuf data into structured TrainPosition objects suitable for
     * map visualization and user interaction.
     * 
     * ## Processing Steps:
     * 1. Fetch raw GTFS-RT feed from MTA API
     * 2. Parse vehicle positions and trip updates
     * 3. Cross-reference data to build complete train records
     * 4. Extract NYC-specific extensions (train IDs, directions)
     * 5. Generate user-friendly train position objects
     * 
     * ## Data Structures:
     * - Vehicle positions: GPS coordinates and movement status
     * - Trip updates: Schedule adherence and stop predictions
     * - Combined data: Complete train state for visualization
     * 
     * ## Performance Considerations:
     * - Processes hundreds of entities in milliseconds
     * - Uses dictionaries for O(1) lookups during cross-referencing
     * - Updates UI atomically to prevent flickering
     * 
     * ## Error Handling:
     * - Gracefully handles network failures
     * - Continues with partial data if some entities are malformed
     * - Logs errors for debugging without crashing the app
     */
    @MainActor
    func fetchTrainPositions() async {
        isLoading = true
        error = nil
        
        do {
            let feed = try await mtaService.fetchFeed()
            trainPositions = dataProcessor.processTrainPositions(from: feed)
            
            print("Successfully parsed \(trainPositions.count) train positions")
            if !trainPositions.isEmpty {
                print("Sample train: \(trainPositions[0])")
            }
            
        } catch {
            print("Error fetching train positions:", error)
            self.error = error
        }
        
        isLoading = false
    }
    
    // MARK: - Public Utility Methods
    
    /**
     * Refreshes all data sources
     * 
     * Fetches both base data and real-time train positions,
     * providing a complete data refresh for the user.
     */
    @MainActor
    func refreshAllData() async {
        await fetchBaseData()
        await fetchTrainPositions()
    }
    
    /**
     * Clears current error state
     * 
     * Useful for dismissing error alerts and resetting UI state.
     */
    @MainActor
    func clearError() {
        error = nil
    }
}
