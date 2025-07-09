//
//  WhichWayTests.swift
//  WhichWayTests
//
//  Created by Jack Anderson on 6/15/25.
//

import Testing
@testable import WhichWay

// MARK: - Core App Tests

@Suite("WhichWay Core App Tests")
struct WhichWayTests {

    @Test("App initializes with dependency container")
    func appInitializesWithDependencyContainer() async throws {
        let container = DependencyContainer.makeForCurrentEnvironment()
        #expect(container is DependencyContainer)
    }
    
    @Test("Dependency container creates MTAService")
    func dependencyContainerCreatesMTAService() async throws {
        let container = DependencyContainer()
        let service = container.makeMTAService()
        #expect(service is MTAServiceProtocol)
    }
    
    @Test("Dependency container creates GTFSDataProcessor")
    func dependencyContainerCreatesGTFSDataProcessor() async throws {
        let container = DependencyContainer()
        let processor = container.makeGTFSDataProcessor()
        #expect(processor is GTFSDataProcessorProtocol)
    }
    
    @Test("Dependency container creates MapViewModel")
    func dependencyContainerCreatesMapViewModel() async throws {
        let container = DependencyContainer()
        let viewModel = container.makeMapViewModel()
        #expect(viewModel is MapViewModel)
    }
    
    @Test("Environment detection works correctly")
    func environmentDetectionWorksCorrectly() async throws {
        let environment = DependencyContainer.environmentFromSystem()
        #expect(environment == .development || environment == .production)
    }
    
    @Test("Container reset functionality")
    func containerResetFunctionality() async throws {
        let container = DependencyContainer()
        container.reset()
        
        // After reset, should still be able to create services
        let service = container.makeMTAService()
        #expect(service is MTAServiceProtocol)
    }
}
