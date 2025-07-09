//
//  AppStateManager.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/9/25.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - App State

/**
 * AppState - Represents the current state of the application
 * 
 * Used to coordinate startup data loading and user interface display.
 */
enum AppState: Equatable {
    case loading(String)  // Loading with status message
    case loaded           // Data loaded successfully
    case error(String)    // Error occurred with message
    
    static func == (lhs: AppState, rhs: AppState) -> Bool {
        switch (lhs, rhs) {
        case (.loading(let lhsMessage), .loading(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.loaded, .loaded):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

// MARK: - App State Manager

/**
 * AppStateManager - Manages the application startup state and data loading
 * 
 * This class coordinates the startup sequence including:
 * - GTFS data fetching and extraction
 * - SwiftData persistence
 * - UI state management
 * - Error handling and recovery
 * 
 * ## Features:
 * - Observable state changes for UI updates
 * - Progress reporting during data loading
 * - Error recovery with retry functionality
 * - SwiftData integration for persistent storage
 * 
 * ## Usage:
 * Initialize once in the app and provide to the SwiftUI environment.
 * The manager automatically handles the startup sequence.
 */
@MainActor
class AppStateManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Current application state
    @Published var state: AppState = .loading("Initializing...")
    
    // MARK: - Private Properties
    
    /// MTA service for data operations
    private let mtaService: MTAServiceProtocol
    
    /// SwiftData model context for persistence
    private var modelContext: ModelContext?
    
    // MARK: - Initialization
    
    /**
     * Initializes the app state manager with dependency injection
     * 
     * ## Parameters:
     * - mtaService: Service for MTA data operations
     */
    init(mtaService: MTAServiceProtocol = MTAService()) {
        self.mtaService = mtaService
    }
    
    // MARK: - Public Methods
    
    /**
     * Sets the SwiftData model context for persistence operations
     * 
     * ## Parameters:
     * - context: SwiftData model context from the environment
     */
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    /**
     * Starts the application data loading sequence
     * 
     * This method orchestrates the entire startup process:
     * 1. Downloads GTFS data from MTA
     * 2. Extracts and processes the data
     * 3. Saves to SwiftData for persistence
     * 4. Updates UI state accordingly
     */
    func startDataLoading() async {
        do {
            // Step 1: Download GTFS data
            await updateState(.loading("Downloading subway data..."))
            try await mtaService.fetchBaseData()
            
            // Step 2: Process and save data
            await updateState(.loading("Processing stations and routes..."))
            try await mtaService.decodeBaseData(context: modelContext)
            
            // Step 3: Complete loading
            await updateState(.loading("Finalizing..."))
            
            // Small delay to show completion
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Step 4: Mark as loaded
            await updateState(.loaded)
            
        } catch {
            await updateState(.error("Failed to load subway data: \(error.localizedDescription)"))
        }
    }
    
    /**
     * Retries the data loading process after an error
     * 
     * Resets the state to loading and starts the process again.
     */
    func retryDataLoading() async {
        await updateState(.loading("Retrying..."))
        await startDataLoading()
    }
    
    // MARK: - Private Methods
    
    /**
     * Updates the application state
     * 
     * ## Parameters:
     * - newState: The new state to set
     */
    private func updateState(_ newState: AppState) async {
        await MainActor.run {
            self.state = newState
        }
    }
}