//
//  WhichWayApp.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/15/25.
//

import SwiftUI
import SwiftData

// MARK: - App Entry Point

/**
 * WhichWayApp - Main application entry point
 * 
 * This configures the app-wide dependencies and provides them to the
 * SwiftUI environment for access throughout the app.
 * 
 * ## Architecture:
 * - Uses dependency injection container for service management
 * - Configures SwiftData model container for persistence
 * - Provides environment-based configuration
 * - Maintains clean separation of concerns
 * 
 * ## Dependencies:
 * - SwiftData for persistent storage
 * - DependencyContainer for service injection
 * - Environment-based configuration
 */
@main
struct WhichWayApp: App {
    
    // MARK: - Properties
    
    /// Dependency container for the entire app
    private let dependencyContainer: DependencyContainer
    
    // MARK: - Initialization
    
    /**
     * Initializes the app with dependency injection
     * 
     * Creates a dependency container appropriate for the current
     * environment and configures it for the app's needs.
     */
    init() {
        self.dependencyContainer = DependencyContainer.makeForCurrentEnvironment()
    }
    
    // MARK: - App Scene
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(
            for: [
                SubwayRoute.self,
                SubwayStation.self,
                SubwayRoutePolyline.self
            ]
        )
    }
}


