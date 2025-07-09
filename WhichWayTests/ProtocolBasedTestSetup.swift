//
//  ProtocolBasedTestSetup.swift
//  WhichWayTests
//
//  Created by Jack Anderson on 7/9/25.
//

import Foundation
import Testing
import Zip
@testable import WhichWay

// MARK: - Service Protocols for Testing

// MARK: - Mock Implementations

/// Mock MTAService for testing
class MockMTAService: MTAServiceProtocol {
    
    // MARK: - Mock Configuration
    
    var shouldThrowError = false
    var errorToThrow: Error = GTFSDataError.downloadFailed
    var mockFeedData: TransitRealtime_FeedMessage?
    var fetchDelay: TimeInterval = 0
    
    // MARK: - Call Tracking
    
    private(set) var fetchFeedCallCount = 0
    private(set) var fetchBaseDataCallCount = 0
    private(set) var decodeBaseDataCallCount = 0
    
    // MARK: - Properties
    
    /// Path where extracted GTFS data is stored
    private var extractionPath: URL?
    
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
    
    func fetchBaseData() async throws {
        fetchBaseDataCallCount += 1
        
        if fetchDelay > 0 {
            try await Task.sleep(for: .seconds(fetchDelay))
        }
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        // Use the actual ZIP file from the test bundle
        let testBundle = Bundle(for: type(of: self))
        guard let zipPath = testBundle.url(forResource: "gtfs_subway", withExtension: "zip") else {
            throw GTFSDataError.downloadFailed
        }
        
        // Create temporary directory for extraction
        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("mock_gtfs_data")
        
        do {
            // Clean up any existing temp directory
            try? FileManager.default.removeItem(at: tempDir)
            
            // Create fresh temp directory
            try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            // Extract ZIP contents
            try Zip.unzipFile(zipPath, destination: tempDir, overwrite: true, password: nil)
            
            // Store the extraction path for decodeBaseData
            extractionPath = tempDir
            
        } catch {
            // Clean up temp directory on error
            try? FileManager.default.removeItem(at: tempDir)
            throw GTFSDataError.extractionFailed
        }
    }
    
    func decodeBaseData() async throws {
        decodeBaseDataCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        guard let extractionPath = extractionPath else {
            throw GTFSDataError.extractionFailed
        }
        
        do {
            // Parse stops.txt for station information
            try await parseStopsFile(at: extractionPath)
            
            // Parse routes.txt for route definitions
            try await parseRoutesFile(at: extractionPath)
            
            // Parse agency.txt for agency information
            try await parseAgencyFile(at: extractionPath)
            
            // Parse calendar.txt for service calendar
            try await parseCalendarFile(at: extractionPath)
            
            // Parse trips.txt for trip information
            try await parseTripsFile(at: extractionPath)
            
            // Parse transfers.txt for transfer rules
            try await parseTransfersFile(at: extractionPath)
            
            // Clean up temporary files after successful processing
            try? FileManager.default.removeItem(at: extractionPath)
            
        } catch {
            // Clean up temp directory on error
            try? FileManager.default.removeItem(at: extractionPath)
            throw GTFSDataError.processingFailed
        }
    }
    
    // MARK: - Test Utilities
    
    func reset() {
        shouldThrowError = false
        errorToThrow = GTFSDataError.downloadFailed
        mockFeedData = nil
        fetchDelay = 0
        fetchFeedCallCount = 0
        fetchBaseDataCallCount = 0
        decodeBaseDataCallCount = 0
        extractionPath = nil
    }
    
    func configureMockFeed(with entities: [TransitRealtime_FeedEntity]) {
        mockFeedData = GTFSRTTestDataBuilder.createFeed(entities: entities)
    }
    
    // MARK: - CSV Parsing Methods
    
    /**
     * Parses stops.txt and creates SubwayStation models
     */
    private func parseStopsFile(at path: URL) async throws {
        let stopsFile = path.appendingPathComponent("stops.txt")
        let content = try String(contentsOf: stopsFile)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard let headerLine = lines.first else { return }
        let headers = parseCSVRow(headerLine)
        
        // Find column indices
        guard let stopIdIndex = headers.firstIndex(of: "stop_id"),
              let stopNameIndex = headers.firstIndex(of: "stop_name"),
              let stopLatIndex = headers.firstIndex(of: "stop_lat"),
              let stopLonIndex = headers.firstIndex(of: "stop_lon"),
              let locationTypeIndex = headers.firstIndex(of: "location_type") else {
            throw GTFSDataError.processingFailed
        }
        
        // Parse data rows
        var stationCount = 0
        for line in lines.dropFirst() {
            let values = parseCSVRow(line)
            guard values.count > max(stopIdIndex, stopNameIndex, stopLatIndex, stopLonIndex, locationTypeIndex) else { continue }
            
            // Only process stations (location_type = 1), not platforms
            guard values[locationTypeIndex] == "1" else { continue }
            
            guard let latitude = Double(values[stopLatIndex]),
                  let longitude = Double(values[stopLonIndex]) else { continue }
            
            let station = SubwayStation(
                id: values[stopIdIndex],
                name: values[stopNameIndex],
                latitude: latitude,
                longitude: longitude
            )
            
            stationCount += 1
            print("Mock parsed station: \(station.name) at \(station.latitude), \(station.longitude)")
        }
        print("Mock parsed \(stationCount) stations total")
    }
    
    /**
     * Parses routes.txt and creates SubwayRoute models
     */
    private func parseRoutesFile(at path: URL) async throws {
        let routesFile = path.appendingPathComponent("routes.txt")
        let content = try String(contentsOf: routesFile)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard let headerLine = lines.first else { return }
        let headers = parseCSVRow(headerLine)
        
        // Find column indices
        guard let routeIdIndex = headers.firstIndex(of: "route_id"),
              let agencyIdIndex = headers.firstIndex(of: "agency_id"),
              let routeShortNameIndex = headers.firstIndex(of: "route_short_name"),
              let routeLongNameIndex = headers.firstIndex(of: "route_long_name"),
              let routeDescIndex = headers.firstIndex(of: "route_desc"),
              let routeUrlIndex = headers.firstIndex(of: "route_url") else {
            throw GTFSDataError.processingFailed
        }
        
        // Optional fields
        let routeColorIndex = headers.firstIndex(of: "route_color")
        let routeTextColorIndex = headers.firstIndex(of: "route_text_color")
        
        // Parse data rows
        var routeCount = 0
        for line in lines.dropFirst() {
            let values = parseCSVRow(line)
            guard values.count > max(routeIdIndex, agencyIdIndex, routeShortNameIndex, routeLongNameIndex, routeDescIndex, routeUrlIndex) else { continue }
            
            let routeColor = routeColorIndex != nil && values.count > routeColorIndex! ? values[routeColorIndex!] : nil
            let routeTextColor = routeTextColorIndex != nil && values.count > routeTextColorIndex! ? values[routeTextColorIndex!] : nil
            
            let route = SubwayRoute(
                routeId: values[routeIdIndex],
                agencyId: values[agencyIdIndex],
                routeShortName: values[routeShortNameIndex],
                routeLongName: values[routeLongNameIndex],
                routeDescription: values[routeDescIndex],
                routeUrl: values[routeUrlIndex],
                routeColor: routeColor?.isEmpty == false ? routeColor : nil,
                routeTextColor: routeTextColor?.isEmpty == false ? routeTextColor : nil
            )
            
            routeCount += 1
            print("Mock parsed route: \(route.routeShortName) - \(route.routeLongName)")
        }
        print("Mock parsed \(routeCount) routes total")
    }
    
    /**
     * Parses agency.txt for agency information
     */
    private func parseAgencyFile(at path: URL) async throws {
        let agencyFile = path.appendingPathComponent("agency.txt")
        let content = try String(contentsOf: agencyFile)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard let headerLine = lines.first else { return }
        let headers = parseCSVRow(headerLine)
        
        // Parse data rows
        for line in lines.dropFirst() {
            let values = parseCSVRow(line)
            print("Mock parsed agency: \(values.joined(separator: ", "))")
        }
    }
    
    /**
     * Parses calendar.txt for service calendar information
     */
    private func parseCalendarFile(at path: URL) async throws {
        let calendarFile = path.appendingPathComponent("calendar.txt")
        let content = try String(contentsOf: calendarFile)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard let headerLine = lines.first else { return }
        let headers = parseCSVRow(headerLine)
        
        // Parse data rows
        for line in lines.dropFirst() {
            let values = parseCSVRow(line)
            print("Mock parsed calendar: \(values.joined(separator: ", "))")
        }
    }
    
    /**
     * Parses trips.txt for trip information
     */
    private func parseTripsFile(at path: URL) async throws {
        let tripsFile = path.appendingPathComponent("trips.txt")
        let content = try String(contentsOf: tripsFile)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard let headerLine = lines.first else { return }
        let headers = parseCSVRow(headerLine)
        
        // Parse first few data rows for testing
        for line in lines.dropFirst().prefix(5) {
            let values = parseCSVRow(line)
            print("Mock parsed trip: \(values.joined(separator: ", "))")
        }
    }
    
    /**
     * Parses transfers.txt for transfer rules
     */
    private func parseTransfersFile(at path: URL) async throws {
        let transfersFile = path.appendingPathComponent("transfers.txt")
        let content = try String(contentsOf: transfersFile)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard let headerLine = lines.first else { return }
        let headers = parseCSVRow(headerLine)
        
        // Parse first few data rows for testing
        for line in lines.dropFirst().prefix(5) {
            let values = parseCSVRow(line)
            print("Mock parsed transfer: \(values.joined(separator: ", "))")
        }
    }
    
    /**
     * Parses a CSV row into individual values
     */
    private func parseCSVRow(_ row: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var inQuotes = false
        var i = row.startIndex
        
        while i < row.endIndex {
            let char = row[i]
            
            if char == "\"" {
                if inQuotes && i < row.index(before: row.endIndex) && row[row.index(after: i)] == "\"" {
                    // Escaped quote
                    currentValue += "\""
                    i = row.index(after: i)
                } else {
                    // Start or end of quoted field
                    inQuotes.toggle()
                }
            } else if char == "," && !inQuotes {
                // End of field
                values.append(currentValue.trimmingCharacters(in: .whitespacesAndNewlines))
                currentValue = ""
            } else {
                currentValue += String(char)
            }
            
            i = row.index(after: i)
        }
        
        // Add the last field
        values.append(currentValue.trimmingCharacters(in: .whitespacesAndNewlines))
        
        return values
    }
}

/// Mock GTFS Data Processor for testing
class MockGTFSDataProcessor: GTFSDataProcessorProtocol {
    
    // MARK: - Mock Configuration
    
    var mockTrainPositions: [TrainPosition] = []
    var mockStopInfos: [StopInfo] = []
    var shouldReturnNilPosition = false
    
    // MARK: - Call Tracking
    
    private(set) var processTrainPositionsCallCount = 0
    private(set) var extractStopInfosCallCount = 0
    private(set) var createTrainPositionCallCount = 0
    
    // MARK: - Protocol Implementation
    
    func processTrainPositions(from feed: TransitRealtime_FeedMessage) -> [TrainPosition] {
        processTrainPositionsCallCount += 1
        return mockTrainPositions
    }
    
    func extractStopInfos(from tripUpdate: TransitRealtime_TripUpdate) -> [StopInfo] {
        extractStopInfosCallCount += 1
        return mockStopInfos
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
            nextStops: mockStopInfos
        )
    }
    
    // MARK: - Test Utilities
    
    func reset() {
        mockTrainPositions = []
        mockStopInfos = []
        shouldReturnNilPosition = false
        processTrainPositionsCallCount = 0
        extractStopInfosCallCount = 0
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
class TestableMapViewModel: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var trainPositions: [TrainPosition] = []
    @Published var isLoading = false
    @Published var error: Error?
    
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
            let feed = try await mtaService.fetchFeed()
            trainPositions = dataProcessor.processTrainPositions(from: feed)
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
        #expect(mockService.fetchFeedCallCount == 2) // Once in init, once in test
        #expect(mockProcessor.processTrainPositionsCallCount == 2)
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
        #expect(mockService.fetchFeedCallCount >= 1)
        #expect(mockProcessor.processTrainPositionsCallCount >= 1)
    }
    
    @Test("GTFS ZIP file processing")
    func testGTFSZipFileProcessing() async throws {
        // Arrange
        let mockService = MockMTAService()
        
        // Act
        try await mockService.fetchBaseData()
        try await mockService.decodeBaseData()
        
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
            try await mockService.decodeBaseData()
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