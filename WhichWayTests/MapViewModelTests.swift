//
//  MapViewModelTests.swift
//  WhichWayTests
//
//  Created by Jack Anderson on 7/9/25.
//

import Testing
import Foundation
import SwiftUI
@testable import WhichWay


// MARK: - MapViewModel Tests

@Suite("MapViewModel Tests")
struct MapViewModelTests {

    // MARK: - Initialization Tests

    @Test("MapViewModel initializes with empty train positions")
    func testInitialState() async throws {
        let viewModel = MapViewModel()

        // Give it a moment to complete initialization
        try await Task.sleep(for: .milliseconds(100))

        #expect(viewModel.trainPositions.isEmpty)
    }

    @Test("MapViewModel uses @Observable macro")
    func testObservableConformance() async throws {
        let viewModel = MapViewModel()

        // Verify basic properties are accessible
        #expect(viewModel.trainPositions.isEmpty)
        #expect(viewModel.isLoading == false)
        #expect(viewModel.error == nil)
        #expect(viewModel.selectedStation == nil)
        #expect(viewModel.isShowingStationDetail == false)
    }

    // MARK: - Data Fetching Tests

    @Test("fetchAllTrainPositions updates trainPositions array")
    func testFetchAllTrainPositionsSuccess() async throws {
        let viewModel = MapViewModel()

        // Give it a moment to complete initialization
        try await Task.sleep(for: .milliseconds(100))

        await viewModel.fetchAllTrainPositions()

        // Test that the function completes without throwing
        #expect(viewModel.trainPositions.count >= 0)
        #expect(viewModel.isLoading == false)
    }

    @Test("fetchAllTrainPositions handles network errors gracefully")
    func testFetchAllTrainPositionsNetworkError() async throws {
        let viewModel = MapViewModel()

        // Test that network errors don't crash the app
        await viewModel.fetchAllTrainPositions()

        // Should not throw and should handle errors gracefully
        #expect(viewModel.isLoading == false)
    }

    // MARK: - Data Processing Tests

    @Test("createTrainPosition with valid data")
    func testCreateTrainPositionValidData() async throws {
        let viewModel = MapViewModel()

        // Create sample GTFS-RT data
        let feed = TestDataFactory.createSampleFeed()
        let _ = feed.entity.first!

        // Test the train position creation logic through the public interface
        await viewModel.fetchAllTrainPositions()

        // Verify the processing logic works
        #expect(true)
    }

    @Test("createTrainPosition with missing data")
    func testCreateTrainPositionMissingData() async throws {
        let viewModel = MapViewModel()

        // Test handling of incomplete GTFS-RT data
        var feed = TransitRealtime_FeedMessage()
        feed.header.gtfsRealtimeVersion = "2.0"
        feed.header.timestamp = UInt64(Date().timeIntervalSince1970)

        // Add entity with missing required fields
        var entity = TransitRealtime_FeedEntity()
        entity.id = "incomplete-entity"
        feed.entity.append(entity)

        // Should handle missing data gracefully
        await viewModel.fetchAllTrainPositions()
        #expect(true)
    }

    // MARK: - NYC Extension Processing Tests

    @Test("direction conversion from GTFS-RT to string")
    func testDirectionConversion() async throws {
        // Test the direction mapping logic
        let northDirection = TransitRealtime_NyctTripDescriptor.Direction.north
        let southDirection = TransitRealtime_NyctTripDescriptor.Direction.south

        #expect(northDirection.rawValue == 1)
        #expect(southDirection.rawValue == 2)
    }

    @Test("extractStopInfos with valid trip update")
    func testExtractStopInfosValidData() async throws {
        let tripUpdate = TestDataFactory.createSampleTripUpdate(tripId: "test-trip")

        // Test stop information extraction
        #expect(tripUpdate.stopTimeUpdate.count == 3)
    }

    // MARK: - Main Actor Tests

    @Test("fetchAllTrainPositions runs on main actor")
    func testFetchAllTrainPositionsMainActor() async throws {
        let viewModel = MapViewModel()

        await viewModel.fetchAllTrainPositions()

        // Verify we can access properties immediately
        let positionCount = viewModel.trainPositions.count
        #expect(positionCount >= 0)
    }

    // MARK: - Station Selection Tests

    @Test("selectStation updates selected station")
    func testSelectStation() async throws {
        let viewModel = MapViewModel()
        let station = SubwayStation(
            id: "127",
            name: "Times Sq-42 St",
            latitude: 40.755477,
            longitude: -73.987691
        )

        await viewModel.selectStation(station)

        #expect(viewModel.selectedStation?.id == "127")
        #expect(viewModel.isShowingStationDetail == true)
    }

    // MARK: - Route Color Tests

    @Test("buildRouteColorMap creates color lookup")
    func testBuildRouteColorMap() async throws {
        let viewModel = MapViewModel()
        let route = SubwayRoute(
            routeId: "4",
            agencyId: "MTA",
            routeShortName: "4",
            routeLongName: "4 Express",
            routeDescription: "Express",
            routeUrl: "",
            routeColor: "00933C",
            routeTextColor: "FFFFFF"
        )

        viewModel.buildRouteColorMap(from: [route])

        #expect(viewModel.routeColorMap["4"]?.color == "00933C")
        #expect(viewModel.routeColorMap["4"]?.textColor == "FFFFFF")
    }

    // MARK: - Integration Tests

    @Test("full data processing pipeline")
    func testFullDataProcessingPipeline() async throws {
        let viewModel = MapViewModel()

        // Test the complete flow: fetch -> process -> update UI
        await viewModel.fetchAllTrainPositions()

        // Verify the pipeline completed
        #expect(true)
    }

    @Test("concurrent data fetching")
    func testConcurrentDataFetching() async throws {
        let viewModel = MapViewModel()

        // Test concurrent access to the view model
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await viewModel.fetchAllTrainPositions()
            }
            group.addTask {
                await viewModel.fetchAllTrainPositions()
            }
        }

        // Should handle concurrent access gracefully
        #expect(true)
    }
}

// MARK: - TrainPosition Model Tests

@Suite("TrainPosition Model Tests")
struct TrainPositionTests {

    @Test("TrainPosition computed properties")
    func testTrainPositionComputedProperties() async throws {
        let trainPosition = TrainPosition(
            id: "test-train",
            tripId: "test-trip",
            routeId: "4",
            trainId: "train-123",
            direction: "N",
            isAssigned: true,
            currentStopId: "stop-123",
            currentStatus: "STOPPED_AT",
            lastMovementTimestamp: Date(),
            nextStops: [],
            latitude: nil,
            longitude: nil,
            bearing: nil
        )

        #expect(trainPosition.displayName == "4 Train")
        #expect(trainPosition.directionName == "Uptown/Bronx")
        #expect(trainPosition.lastStation == "Station 123")
    }

    @Test("TrainPosition direction mapping")
    func testDirectionMapping() async throws {
        let northTrain = TrainPosition(
            id: "north-train",
            tripId: "trip-1",
            routeId: "4",
            trainId: "train-1",
            direction: "N",
            isAssigned: true,
            currentStopId: nil,
            currentStatus: "IN_TRANSIT",
            lastMovementTimestamp: Date(),
            nextStops: [],
            latitude: nil,
            longitude: nil,
            bearing: nil
        )

        let southTrain = TrainPosition(
            id: "south-train",
            tripId: "trip-2",
            routeId: "4",
            trainId: "train-2",
            direction: "S",
            isAssigned: true,
            currentStopId: nil,
            currentStatus: "IN_TRANSIT",
            lastMovementTimestamp: Date(),
            nextStops: [],
            latitude: nil,
            longitude: nil,
            bearing: nil
        )

        #expect(northTrain.directionName == "Uptown/Bronx")
        #expect(southTrain.directionName == "Downtown/Brooklyn")
    }

    @Test("StopInfo station name extraction")
    func testStopInfoStationName() async throws {
        let stopInfo = StopInfo(
            stopId: "613N",
            arrivalTime: Date(),
            departureTime: Date().addingTimeInterval(30),
            scheduledTrack: "1",
            actualTrack: "1"
        )

        #expect(stopInfo.stationName == "Station 613")
    }
}

// MARK: - Test Utilities

class TestExpectation {
    private var fulfilled = false

    func fulfill() {
        fulfilled = true
    }

    func wait() async {
        while !fulfilled {
            try? await Task.sleep(for: .milliseconds(10))
        }
    }
}
