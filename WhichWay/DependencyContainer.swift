//
//  DependencyContainer.swift
//  WhichWay
//
//  Created by Jack Anderson on 7/9/25.
//

import Foundation
import SwiftUI

// MARK: - Dependency Container

/**
 * DependencyContainer - Manages app-wide dependency injection
 * 
 * This class provides a centralized location for configuring and managing
 * all application dependencies, enabling easy testing and flexibility.
 * 
 * ## Design Benefits:
 * - Centralized dependency management
 * - Easy testing with mock implementations
 * - Consistent configuration across the app
 * - Lazy initialization for performance
 * - Clear separation of concerns
 * 
 * ## Usage:
 * ```swift
 * let container = DependencyContainer()
 * let mapViewModel = container.makeMapViewModel()
 * ```
 */
class DependencyContainer {
    
    // MARK: - Singleton
    
    /// Shared instance for app-wide dependency management
    static let shared = DependencyContainer()
    
    // MARK: - Configuration
    
    /// Configuration for different environments (production, testing, etc.)
    enum Environment {
        case production
        case testing
        case development
    }
    
    /// Current environment configuration
    private let environment: Environment
    
    // MARK: - Initialization
    
    /**
     * Initializes the dependency container
     * 
     * ## Parameters:
     * - environment: The environment configuration (defaults to production)
     * 
     * ## Example:
     * ```swift
     * // Production
     * let container = DependencyContainer()
     * 
     * // Testing
     * let container = DependencyContainer(environment: .testing)
     * ```
     */
    init(environment: Environment = .production) {
        self.environment = environment
    }
    
    // MARK: - Service Factories
    
    /**
     * Creates an MTAService instance
     * 
     * ## Returns:
     * Configured MTAService with appropriate dependencies
     */
    func makeMTAService() -> MTAServiceProtocol {
        switch environment {
        case .production, .development:
            return MTAService(session: URLSession.shared)
        case .testing:
            // In testing, you might want to use a mock
            return MTAService(session: URLSession.shared)
        }
    }
    
    /**
     * Creates a GTFSDataProcessor instance
     * 
     * ## Returns:
     * Configured GTFSDataProcessor with appropriate dependencies
     */
    func makeGTFSDataProcessor() -> GTFSDataProcessorProtocol {
        let stationResolver = makeStationNameResolver()
        return GTFSDataProcessor(stationResolver: stationResolver)
    }
    
    /**
     * Creates a StationNameResolver instance
     * 
     * ## Returns:
     * Configured StationNameResolver with station data
     */
    func makeStationNameResolver() -> StationNameResolverProtocol {
        return StationNameResolver()
    }
    
    /**
     * Creates a MapViewModel instance
     * 
     * ## Returns:
     * Configured MapViewModel with all necessary dependencies
     */
    func makeMapViewModel() -> MapViewModel {
        let mtaService = makeMTAService()
        let dataProcessor = makeGTFSDataProcessor()
        
        return MapViewModel(
            mtaService: mtaService,
            dataProcessor: dataProcessor
        )
    }
    
    // MARK: - Utility Methods
    
    /**
     * Resets all cached dependencies
     * 
     * Useful for testing or when configuration changes.
     */
    func reset() {
        // In a more complex app, you might have cached instances to clear
        // For now, each make* method creates fresh instances
    }
}

// MARK: - Environment Variable Support

extension DependencyContainer {
    
    /**
     * Determines environment from system environment variables
     * 
     * ## Returns:
     * Environment configuration based on system settings
     */
    static func environmentFromSystem() -> Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    /**
     * Creates a container with system-determined environment
     * 
     * ## Returns:
     * DependencyContainer configured for current system environment
     */
    static func makeForCurrentEnvironment() -> DependencyContainer {
        return DependencyContainer(environment: environmentFromSystem())
    }
}

// MARK: - SwiftUI Environment Key

/**
 * SwiftUI environment key for dependency injection
 * 
 * This enables passing the dependency container through the SwiftUI
 * environment for access in views and view models.
 */
private struct DependencyContainerKey: EnvironmentKey {
    static let defaultValue: DependencyContainer = .shared
}

extension EnvironmentValues {
    var dependencyContainer: DependencyContainer {
        get { self[DependencyContainerKey.self] }
        set { self[DependencyContainerKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /**
     * Provides a dependency container to the view hierarchy
     * 
     * ## Parameters:
     * - container: The dependency container to inject
     * 
     * ## Returns:
     * View with dependency container available in environment
     * 
     * ## Example:
     * ```swift
     * ContentView()
     *     .dependencyContainer(myContainer)
     * ```
     */
    func dependencyContainer(_ container: DependencyContainer) -> some View {
        environment(\.dependencyContainer, container)
    }
}