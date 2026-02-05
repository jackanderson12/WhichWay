//
//  ProtocolBasedTestSetup.swift
//  WhichWayTests
//
//  Created by Jack Anderson on 7/9/25.
//

import Foundation
import Testing
import SwiftData
import Zip
@testable import WhichWay

// MARK: - Service Protocols for Testing

// MARK: - Mock Implementations

/// Mock MTAService for testing
class MockMTAService: MTAServiceProtocol, @unchecked Sendable {

    // MARK: - Mock Configuration

    var shouldThrowError = false
    var errorToThrow: Error = GTFSDataError.downloadFailed
    var mockFeedData: TransitRealtime_FeedMessage?
    var mockFeeds: [TransitRealtime_FeedMessage] = []
    var fetchDelay: TimeInterval = 0
    var mockChildStopIds: [String: [String]] = [:]
    var mockStationRoutes: [String: [String]] = [:]
    var mockChildToParentMap: [String: String] = [:]

    // MARK: - Call Tracking

    private(set) var fetchFeedCallCount = 0
    private(set) var fetchAllFeedsCallCount = 0
    private(set) var fetchBaseDataCallCount = 0
    private(set) var decodeBaseDataCallCount = 0

    // MARK: - Protocol Implementation

    func fetchFeed() async throws -> TransitRealtime_FeedMessage {
        fetchFeedCallCount += 1

        if fetchDelay > 0 {
            try await Task.sleep(for: .seconds(fetchDelay))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        return mockFeedData ?? TransitRealtime_FeedMessage()
    }

    func fetchAllFeeds() async throws -> [TransitRealtime_FeedMessage] {
        fetchAllFeedsCallCount += 1

        if fetchDelay > 0 {
            try await Task.sleep(for: .seconds(fetchDelay))
        }

        if shouldThrowError {
            throw errorToThrow
        }

        if !mockFeeds.isEmpty {
            return mockFeeds
        }
        return [mockFeedData ?? TransitRealtime_FeedMessage()]
    }

    func getCachedFeeds() async -> [TransitRealtime_FeedMessage] {
        return mockFeeds.isEmpty ? [mockFeedData ?? TransitRealtime_FeedMessage()] : mockFeeds
    }

    func fetchBaseData() async throws {
        fetchBaseDataCallCount += 1

        if fetchDelay > 0 {
            try await Task.sleep(for: .seconds(fetchDelay))
        }

        if shouldThrowError {
            throw errorToThrow
        }
    }

    func decodeBaseData(context: ModelContext?) async throws {
        decodeBaseDataCallCount += 1

        if shouldThrowError {
            throw errorToThrow
        }
    }

    func getChildStopIds(for stationId: String) async -> [String] {
        return mockChildStopIds[stationId] ?? [stationId, "\(stationId)N", "\(stationId)S"]
    }

    func getRoutesForStation(_ stationId: String) async -> [String] {
        return mockStationRoutes[stationId] ?? []
    }

    func getChildToParentMap() async -> [String: String] {
        return mockChildToParentMap
    }

    // MARK: - Test Utilities

    func reset() {
        shouldThrowError = false
        errorToThrow = GTFSDataError.downloadFailed
        mockFeedData = nil
        mockFeeds = []
        fetchDelay = 0
        fetchFeedCallCount = 0
        fetchAllFeedsCallCount = 0
        fetchBaseDataCallCount = 0
        decodeBaseDataCallCount = 0
        mockChildStopIds = [:]
        mockStationRoutes = [:]
        mockChildToParentMap = [:]
    }

    func configureMockFeed(with entities: [TransitRealtime_FeedEntity]) {
        mockFeedData = GTFSRTTestDataBuilder.createFeed(entities: entities)
    }
}

/// Mock GTFS Data Processor for testing
class MockGTFSDataProcessor: GTFSDataProcessorProtocol {

    // MARK: - Mock Configuration

    var mockTrainPositions: [TrainPosition] = []
    var mockStopInfos: [StopInfo] = []
    var mockArrivals: [StationArrival] = []
    var shouldReturnNilPosition = false

    // MARK: - Call Tracking

    private(set) var processTrainPositionsCallCount = 0
    private(set) var processAllFeedsCallCount = 0
    private(set) var extractStopInfosCallCount = 0
    private(set) var extractArrivalsCallCount = 0
    private(set) var createTrainPositionCallCount = 0

    // MARK: - Protocol Implementation

    func processTrainPositions(from feed: TransitRealtime_FeedMessage) -> [TrainPosition] {
        processTrainPositionsCallCount += 1
        return mockTrainPositions
    }

    func processAllFeeds(_ feeds: [TransitRealtime_FeedMessage]) -> [TrainPosition] {
        processAllFeedsCallCount += 1
        return mockTrainPositions
    }

    func extractStopInfos(from tripUpdate: TransitRealtime_TripUpdate) -> [StopInfo] {
        extractStopInfosCallCount += 1
        return mockStopInfos
    }

    func extractArrivals(
        for stationId: String,
        childStopIds: [String],
        from feeds: [TransitRealtime_FeedMessage],
        routeColors: [String: (color: String, textColor: String)]
    ) -> [StationArrival] {
        extractArrivalsCallCount += 1
        return mockArrivals
    }

    func createTrainPosition(
        tripId: String,
        vehicle: TransitRealtime_VehiclePosition?,
        tripUpdate: TransitRealtime_TripUpdate?
    ) -> TrainPosition? {
        createTrainPositionCallCount += 1

        if shouldReturnNilPosition {
            return nil
        }

        return TrainPosition(
            id: tripId,
            tripId: tripId,
            routeId: vehicle?.trip.routeID ?? "TEST",
            trainId: "TEST-TRAIN",
            direction: "N",
            isAssigned: true,
            currentStopId: vehicle?.stopID,
            currentStatus: "STOPPED_AT",
            lastMovementTimestamp: Date(),
            nextStops: mockStopInfos,
            latitude: nil,
            longitude: nil,
            bearing: nil
        )
    }

    // MARK: - Test Utilities

    func reset() {
        mockTrainPositions = []
        mockStopInfos = []
        mockArrivals = []
        shouldReturnNilPosition = false
        processTrainPositionsCallCount = 0
        processAllFeedsCallCount = 0
        extractStopInfosCallCount = 0
        extractArrivalsCallCount = 0
        createTrainPositionCallCount = 0
    }
}

/// Mock Station Name Resolver for testing
class MockStationNameResolver: StationNameResolverProtocol {
    
    // MARK: - Mock Configuration
    
    var mockStationNames: [String: String] = [:]
    var mockCoordinates: [String: (latitude: Double, longitude: Double)] = [:]
    
    // MARK: - Call Tracking
    
    private(set) var resolveNameCallCount = 0
    private(set) var resolveCoordinateCallCount = 0
    
    // MARK: - Protocol Implementation
    
    func resolveName(for stopId: String) -> String {
        resolveNameCallCount += 1
        
        // Remove direction suffix for lookup
        let cleanId = stopId.replacingOccurrences(of: "[NS]$", with: "", options: .regularExpression)
        
        return mockStationNames[cleanId] ?? "Unknown Station"
    }
    
    func resolveCoordinate(for stopId: String) -> (latitude: Double, longitude: Double)? {
        resolveCoordinateCallCount += 1
        
        let cleanId = stopId.replacingOccurrences(of: "[NS]$", with: "", options: .regularExpression)
        
        return mockCoordinates[cleanId]
    }
    
    // MARK: - Test Utilities
    
    func reset() {
        mockStationNames = [:]
        mockCoordinates = [:]
        resolveNameCallCount = 0
        resolveCoordinateCallCount = 0
    }
    
    func addMockStation(stopId: String, name: String, coordinate: (latitude: Double, longitude: Double)) {
        mockStationNames[stopId] = name
        mockCoordinates[stopId] = coordinate
    }
}

// MARK: - Testable MapViewModel

/// Enhanced MapViewModel with dependency injection for testing
@Observable
class TestableMapViewModel {

    // MARK: - Properties

    var trainPositions: [TrainPosition] = []
    var isLoading = false
    var error: Error?

    // MARK: - Dependencies

    private let mtaService: MTAServiceProtocol
    private let dataProcessor: GTFSDataProcessorProtocol
    private let stationResolver: StationNameResolverProtocol

    // MARK: - Initialization

    init(
        mtaService: MTAServiceProtocol,
        dataProcessor: GTFSDataProcessorProtocol,
        stationResolver: StationNameResolverProtocol
    ) {
        self.mtaService = mtaService
        self.dataProcessor = dataProcessor
        self.stationResolver = stationResolver

        // Auto-fetch data on initialization
        Task {
            await fetchBaseData()
            await fetchTrainPositions()
        }
    }

    // MARK: - Public Methods

    @MainActor
    func fetchBaseData() async {
        do {
            try await mtaService.fetchBaseData()
        } catch {
            self.error = error
        }
    }

    @MainActor
    func fetchTrainPositions() async {
        isLoading = true
        error = nil

        do {
            let feeds = try await mtaService.fetchAllFeeds()
            trainPositions = dataProcessor.processAllFeeds(feeds)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    @MainActor
    func refreshData() async {
        await fetchBaseData()
        await fetchTrainPositions()
    }
}

// MARK: - Test Suite for Protocol-Based Architecture

@Suite("Protocol-Based Architecture Tests")
struct ProtocolBasedArchitectureTests {
    
    @Test("TestableMapViewModel with mocked dependencies")
    func testMapViewModelWithMocks() async throws {
        // Arrange
        let mockService = MockMTAService()
        let mockProcessor = MockGTFSDataProcessor()
        let mockResolver = MockStationNameResolver()
        
        let samplePosition = TestDataFactory.createSampleTrainPosition()
        mockProcessor.mockTrainPositions = [samplePosition]
        
        let viewModel = TestableMapViewModel(
            mtaService: mockService,
            dataProcessor: mockProcessor,
            stationResolver: mockResolver
        )
        
        // Give initialization time to complete
        try await Task.sleep(for: .milliseconds(100))
        
        // Act
        await viewModel.fetchTrainPositions()
        
        // Assert
        #expect(mockService.fetchAllFeedsCallCount == 2) // Once in init, once in test
        #expect(mockProcessor.processAllFeedsCallCount == 2)
        #expect(viewModel.trainPositions.count == 1)
        #expect(viewModel.trainPositions.first?.id == samplePosition.id)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
    }
    
    @Test("TestableMapViewModel error handling")
    func testMapViewModelErrorHandling() async throws {
        // Arrange
        let mockService = MockMTAService()
        let mockProcessor = MockGTFSDataProcessor()
        let mockResolver = MockStationNameResolver()
        
        mockService.shouldThrowError = true
        mockService.errorToThrow = GTFSDataError.downloadFailed
        
        let viewModel = TestableMapViewModel(
            mtaService: mockService,
            dataProcessor: mockProcessor,
            stationResolver: mockResolver
        )
        
        // Give initialization time to complete
        try await Task.sleep(for: .milliseconds(100))
        
        // Act
        await viewModel.fetchTrainPositions()
        
        // Assert
        #expect(viewModel.error != nil)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.trainPositions.isEmpty)
    }
    
    @Test("MockMTAService call tracking")
    func testMockServiceCallTracking() async throws {
        let mockService = MockMTAService()
        
        // Test initial state
        #expect(mockService.fetchFeedCallCount == 0)
        #expect(mockService.fetchBaseDataCallCount == 0)
        
        // Test method calls
        try await mockService.fetchBaseData()
        try await mockService.fetchFeed()
        
        #expect(mockService.fetchFeedCallCount == 1)
        #expect(mockService.fetchBaseDataCallCount == 1)
        
        // Test reset
        mockService.reset()
        #expect(mockService.fetchFeedCallCount == 0)
        #expect(mockService.fetchBaseDataCallCount == 0)
    }
    
    @Test("MockGTFSDataProcessor functionality")
    func testMockDataProcessor() async throws {
        let mockProcessor = MockGTFSDataProcessor()
        
        // Configure mock data
        let samplePosition = TestDataFactory.createSampleTrainPosition()
        mockProcessor.mockTrainPositions = [samplePosition]
        
        // Test processing
        let feed = TransitRealtime_FeedMessage()
        let positions = mockProcessor.processTrainPositions(from: feed)
        
        #expect(positions.count == 1)
        #expect(positions.first?.id == samplePosition.id)
        #expect(mockProcessor.processTrainPositionsCallCount == 1)
    }
    
    @Test("MockStationNameResolver functionality")
    func testMockStationResolver() async throws {
        let mockResolver = MockStationNameResolver()
        
        // Configure mock data
        mockResolver.addMockStation(
            stopId: "127",
            name: "Times Square",
            coordinate: (40.755477, -73.987691)
        )
        
        // Test resolution
        let name = mockResolver.resolveName(for: "127N")
        let coordinate = mockResolver.resolveCoordinate(for: "127S")
        
        #expect(name == "Times Square")
        #expect(coordinate?.latitude == 40.755477)
        #expect(coordinate?.longitude == -73.987691)
        #expect(mockResolver.resolveNameCallCount == 1)
        #expect(mockResolver.resolveCoordinateCallCount == 1)
    }
    
    @Test("Integration test with all mocks")
    func testFullIntegrationWithMocks() async throws {
        // Arrange
        let mockService = MockMTAService()
        let mockProcessor = MockGTFSDataProcessor()
        let mockResolver = MockStationNameResolver()
        
        // Configure realistic test data
        let feedEntities = [
            GTFSRTTestDataBuilder.createVehicleEntity(
                id: "test-vehicle-1",
                tripId: "test-trip-1",
                routeId: "4",
                trainId: "4-1234",
                currentStopId: "127N"
            )
        ]
        
        mockService.configureMockFeed(with: feedEntities)
        
        let expectedPosition = TestDataFactory.createSampleTrainPosition(id: "test-trip-1")
        mockProcessor.mockTrainPositions = [expectedPosition]
        
        mockResolver.addMockStation(
            stopId: "127",
            name: "Times Square",
            coordinate: (40.755477, -73.987691)
        )
        
        // Act
        let viewModel = TestableMapViewModel(
            mtaService: mockService,
            dataProcessor: mockProcessor,
            stationResolver: mockResolver
        )
        
        // Give initialization time to complete
        try await Task.sleep(for: .milliseconds(100))
        
        // Assert
        #expect(viewModel.trainPositions.count == 1)
        #expect(viewModel.error == nil)
        #expect(mockService.fetchAllFeedsCallCount >= 1)
        #expect(mockProcessor.processAllFeedsCallCount >= 1)
    }
    
    @Test("GTFS ZIP file processing")
    func testGTFSZipFileProcessing() async throws {
        // Arrange
        let mockService = MockMTAService()

        // Act
        try await mockService.fetchBaseData()
        try await mockService.decodeBaseData(context: nil)

        // Assert
        #expect(mockService.fetchBaseDataCallCount == 1)
        #expect(mockService.decodeBaseDataCallCount == 1)
    }

    @Test("GTFS error handling")
    func testGTFSErrorHandling() async throws {
        // Arrange
        let mockService = MockMTAService()
        mockService.shouldThrowError = true
        mockService.errorToThrow = GTFSDataError.processingFailed

        // Act & Assert
        await #expect(throws: GTFSDataError.processingFailed) {
            try await mockService.decodeBaseData(context: nil)
        }
        
        #expect(mockService.decodeBaseDataCallCount == 1)
    }
}

// MARK: - Architecture Migration Guide

/*
 MIGRATION GUIDE: Moving to Protocol-Based Architecture
 
 To make your existing code fully testable, consider these changes:
 
 1. UPDATE MTAService.swift:
    - Add MTAServiceProtocol conformance
    - Add dependency injection for URLSession
    - Example: actor MTAService: MTAServiceProtocol { ... }
 
 2. CREATE GTFSDataProcessor.swift:
    - Extract data processing logic from MapViewModel
    - Implement GTFSDataProcessorProtocol
    - Move createTrainPosition and extractStopInfos methods
 
 3. CREATE StationNameResolver.swift:
    - Implement station ID to name mapping
    - Load data from GTFS stops.txt
    - Provide coordinate lookup functionality
 
 4. UPDATE MapViewModel.swift:
    - Accept protocol dependencies in initializer
    - Use TestableMapViewModel as the base implementation
    - Add loading and error state management
 
 5. UPDATE WhichWayApp.swift:
    - Configure dependency injection container
    - Provide real implementations for production
    - Example: MapViewModel(mtaService: MTAService(), ...)
 
 This architecture provides:
 - Full testability with mocks
 - Clear separation of concerns
 - Easy dependency injection
 - Better error handling
 - Improved maintainability
 */