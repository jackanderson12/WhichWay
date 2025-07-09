//
//  TestUtilities.swift
//  WhichWayTests
//
//  Created by Jack Anderson on 7/9/25.
//

import Foundation
import Testing
@testable import WhichWay

// MARK: - Test Data Factories

/**
 * TestDataFactory - Convenience wrapper for creating test data
 * 
 * This provides backward compatibility and convenience methods for tests
 */
struct TestDataFactory {
    
    /// Creates a sample train position for testing
    static func createSampleTrainPosition(id: String = "test-train") -> TrainPosition {
        return TrainPosition(
            id: id,
            tripId: "test-trip-\(id)",
            routeId: "4",
            trainId: "train-\(id)",
            direction: "N",
            isAssigned: true,
            currentStopId: "stop-123",
            currentStatus: "STOPPED_AT",
            lastMovementTimestamp: Date(),
            nextStops: [
                StopInfo(
                    stopId: "stop-124",
                    arrivalTime: Date().addingTimeInterval(120),
                    departureTime: Date().addingTimeInterval(150),
                    scheduledTrack: "1",
                    actualTrack: "1"
                )
            ]
        )
    }
    
    /// Creates a sample GTFS-RT feed with multiple trains
    static func createSampleFeedWithMultipleTrains(
        trainCount: Int = 3,
        routeId: String = "4"
    ) -> TransitRealtime_FeedMessage {
        let entities = (0..<trainCount).map { index in
            GTFSRTTestDataBuilder.createVehicleEntity(
                id: "entity-\(index)",
                tripId: "trip-\(index)",
                routeId: routeId,
                trainId: "\(routeId)-\(1000 + index)",
                currentStopId: "12\(index)N",
                direction: index % 2 == 0 ? .north : .south,
                latitude: 40.7589 + Double(index) * 0.01,
                longitude: -73.9851 + Double(index) * 0.01
            )
        }
        
        return GTFSRTTestDataBuilder.createFeed(entities: entities)
    }
    
    /// Creates a sample GTFS-RT feed with vehicle positions
    static func createSampleFeed(withVehicleCount count: Int = 1) -> TransitRealtime_FeedMessage {
        return createSampleFeedWithMultipleTrains(trainCount: count)
    }
    
    /// Creates a sample trip update with stop time information
    static func createSampleTripUpdate(tripId: String, stopCount: Int = 3) -> TransitRealtime_TripUpdate {
        let stopUpdates = (0..<stopCount).map { index in
            let baseTime = Date().timeIntervalSince1970
            return StopTimeUpdateData(
                stopId: "stop-\(index)",
                arrivalTime: Date(timeIntervalSince1970: baseTime + Double(index * 60)),
                departureTime: Date(timeIntervalSince1970: baseTime + Double(index * 60 + 30))
            )
        }
        
        let entity = GTFSRTTestDataBuilder.createTripUpdateEntity(
            id: "trip-update-\(tripId)",
            tripId: tripId,
            routeId: "4",
            stopUpdates: stopUpdates
        )
        
        return entity.tripUpdate
    }
}

// MARK: - GTFS-RT Test Data Builder

/// Utility class for building GTFS-RT test data
struct GTFSRTTestDataBuilder {
    
    /// Creates a complete GTFS-RT feed with customizable entities
    static func createFeed(
        timestamp: Date = Date(),
        version: String = "2.0",
        entities: [TransitRealtime_FeedEntity] = []
    ) -> TransitRealtime_FeedMessage {
        var feed = TransitRealtime_FeedMessage()
        feed.header.gtfsRealtimeVersion = version
        feed.header.timestamp = UInt64(timestamp.timeIntervalSince1970)
        feed.entity = entities
        return feed
    }
    
    /// Creates a vehicle position entity
    static func createVehicleEntity(
        id: String = "test-vehicle",
        tripId: String = "test-trip",
        routeId: String = "4",
        trainId: String? = nil,
        direction: TransitRealtime_NyctTripDescriptor.Direction = .north,
        currentStopId: String? = nil,
        status: TransitRealtime_VehiclePosition.VehicleStopStatus = .inTransitTo,
        timestamp: Date = Date(),
        latitude: Double? = nil,
        longitude: Double? = nil
    ) -> TransitRealtime_FeedEntity {
        var entity = TransitRealtime_FeedEntity()
        entity.id = id
        
        var vehicle = TransitRealtime_VehiclePosition()
        vehicle.timestamp = UInt64(timestamp.timeIntervalSince1970)
        vehicle.currentStatus = status
        
        if let stopId = currentStopId {
            vehicle.stopID = stopId
        }
        
        // Add position if provided
        if let lat = latitude, let lon = longitude {
            var position = TransitRealtime_Position()
            position.latitude = Float(lat)
            position.longitude = Float(lon)
            vehicle.position = position
        }
        
        // Create trip descriptor
        var trip = TransitRealtime_TripDescriptor()
        trip.tripID = tripId
        trip.routeID = routeId
        
        // Add NYC extensions
        var nyctTrip = TransitRealtime_NyctTripDescriptor()
        nyctTrip.direction = direction
        nyctTrip.isAssigned = true
        
        if let trainId = trainId {
            nyctTrip.trainID = trainId
        }
        
        trip.TransitRealtime_nyctTripDescriptor = nyctTrip
        vehicle.trip = trip
        
        entity.vehicle = vehicle
        return entity
    }
    
    /// Creates a trip update entity
    static func createTripUpdateEntity(
        id: String = "test-trip-update",
        tripId: String = "test-trip",
        routeId: String = "4",
        stopUpdates: [StopTimeUpdateData] = []
    ) -> TransitRealtime_FeedEntity {
        var entity = TransitRealtime_FeedEntity()
        entity.id = id
        
        var tripUpdate = TransitRealtime_TripUpdate()
        
        var trip = TransitRealtime_TripDescriptor()
        trip.tripID = tripId
        trip.routeID = routeId
        tripUpdate.trip = trip
        
        // Add stop time updates
        for updateData in stopUpdates {
            var stopTimeUpdate = TransitRealtime_TripUpdate.StopTimeUpdate()
            stopTimeUpdate.stopID = updateData.stopId
            
            if let arrivalTime = updateData.arrivalTime {
                var arrival = TransitRealtime_TripUpdate.StopTimeEvent()
                arrival.time = Int64(arrivalTime.timeIntervalSince1970)
                stopTimeUpdate.arrival = arrival
            }
            
            if let departureTime = updateData.departureTime {
                var departure = TransitRealtime_TripUpdate.StopTimeEvent()
                departure.time = Int64(departureTime.timeIntervalSince1970)
                stopTimeUpdate.departure = departure
            }
            
            // Add NYC extensions
            if updateData.scheduledTrack != nil || updateData.actualTrack != nil {
                var nyctUpdate = TransitRealtime_NyctStopTimeUpdate()
                nyctUpdate.scheduledTrack = updateData.scheduledTrack ?? ""
                nyctUpdate.actualTrack = updateData.actualTrack ?? ""
                stopTimeUpdate.TransitRealtime_nyctStopTimeUpdate = nyctUpdate
            }
            
            tripUpdate.stopTimeUpdate.append(stopTimeUpdate)
        }
        
        entity.tripUpdate = tripUpdate
        return entity
    }
    
    /// Creates a service alert entity
    static func createServiceAlertEntity(
        id: String = "test-alert",
        headerText: String = "Service Alert",
        descriptionText: String = "Test service alert description",
        cause: TransitRealtime_Alert.Cause = .unknownCause,
        effect: TransitRealtime_Alert.Effect = .unknownEffect,
        routeIds: [String] = ["4"]
    ) -> TransitRealtime_FeedEntity {
        var entity = TransitRealtime_FeedEntity()
        entity.id = id
        
        var alert = TransitRealtime_Alert()
        alert.cause = cause
        alert.effect = effect
        
        // Add header text
        var headerTranslation = TransitRealtime_TranslatedString.Translation()
        headerTranslation.text = headerText
        headerTranslation.language = "en"
        
        var headerString = TransitRealtime_TranslatedString()
        headerString.translation = [headerTranslation]
        alert.headerText = headerString
        
        // Add description text
        var descTranslation = TransitRealtime_TranslatedString.Translation()
        descTranslation.text = descriptionText
        descTranslation.language = "en"
        
        var descString = TransitRealtime_TranslatedString()
        descString.translation = [descTranslation]
        alert.descriptionText = descString
        
        // Add informed entities
        for routeId in routeIds {
            var informedEntity = TransitRealtime_EntitySelector()
            informedEntity.routeID = routeId
            alert.informedEntity.append(informedEntity)
        }
        
        entity.alert = alert
        return entity
    }
}

// MARK: - Stop Time Update Data

/// Helper struct for creating stop time update test data
struct StopTimeUpdateData {
    let stopId: String
    let arrivalTime: Date?
    let departureTime: Date?
    let scheduledTrack: String?
    let actualTrack: String?
    
    init(
        stopId: String,
        arrivalTime: Date? = nil,
        departureTime: Date? = nil,
        scheduledTrack: String? = nil,
        actualTrack: String? = nil
    ) {
        self.stopId = stopId
        self.arrivalTime = arrivalTime
        self.departureTime = departureTime
        self.scheduledTrack = scheduledTrack
        self.actualTrack = actualTrack
    }
}

// MARK: - NYC Transit Test Data

/// Predefined NYC transit test data
struct NYCTransitTestData {
    
    /// Common NYC subway routes
    enum Route: String, CaseIterable {
        case four = "4"
        case five = "5"
        case six = "6"
        case l = "L"
        case n = "N"
        case q = "Q"
        case r = "R"
        case w = "W"
        
        var color: String {
            switch self {
            case .four, .five, .six:
                return "00933C" // Green
            case .l:
                return "A7A9AC" // Gray
            case .n, .q, .r, .w:
                return "FCCC0A" // Yellow
            }
        }
    }
    
    /// Common NYC station stop IDs
    enum StationStopId: String, CaseIterable {
        case timesSquare42St = "127"
        case grandCentral42St = "631"
        case unionSquare14St = "635"
        case wallSt = "142"
        case brooklyn = "417"
        
        var name: String {
            switch self {
            case .timesSquare42St:
                return "Times Sq-42 St"
            case .grandCentral42St:
                return "Grand Central-42 St"
            case .unionSquare14St:
                return "14 St-Union Sq"
            case .wallSt:
                return "Wall St"
            case .brooklyn:
                return "Brooklyn Bridge-City Hall"
            }
        }
        
        var coordinate: (latitude: Double, longitude: Double) {
            switch self {
            case .timesSquare42St:
                return (40.755477, -73.987691)
            case .grandCentral42St:
                return (40.751776, -73.976848)
            case .unionSquare14St:
                return (40.735736, -73.990568)
            case .wallSt:
                return (40.707557, -73.006924)
            case .brooklyn:
                return (40.713065, -74.006094)
            }
        }
    }
    
    /// Creates a realistic NYC subway scenario
    static func createNYCSubwayScenario() -> TransitRealtime_FeedMessage {
        let timesSquareVehicle = GTFSRTTestDataBuilder.createVehicleEntity(
            id: "4-train-times-square",
            tripId: "4-trip-downtown",
            routeId: Route.four.rawValue,
            trainId: "4-1234",
            direction: .south,
            currentStopId: StationStopId.timesSquare42St.rawValue + "S",
            status: .stoppedAt,
            latitude: StationStopId.timesSquare42St.coordinate.latitude,
            longitude: StationStopId.timesSquare42St.coordinate.longitude
        )
        
        let lTrainVehicle = GTFSRTTestDataBuilder.createVehicleEntity(
            id: "l-train-union-square",
            tripId: "l-trip-brooklyn",
            routeId: Route.l.rawValue,
            trainId: "L-5678",
            direction: .east,
            currentStopId: StationStopId.unionSquare14St.rawValue + "E",
            status: .inTransitTo,
            latitude: StationStopId.unionSquare14St.coordinate.latitude,
            longitude: StationStopId.unionSquare14St.coordinate.longitude
        )
        
        let tripUpdate = GTFSRTTestDataBuilder.createTripUpdateEntity(
            id: "4-trip-update",
            tripId: "4-trip-downtown",
            routeId: Route.four.rawValue,
            stopUpdates: [
                StopTimeUpdateData(
                    stopId: StationStopId.unionSquare14St.rawValue + "S",
                    arrivalTime: Date().addingTimeInterval(120),
                    departureTime: Date().addingTimeInterval(150),
                    scheduledTrack: "1",
                    actualTrack: "1"
                ),
                StopTimeUpdateData(
                    stopId: StationStopId.brooklyn.rawValue + "S",
                    arrivalTime: Date().addingTimeInterval(300),
                    departureTime: Date().addingTimeInterval(330),
                    scheduledTrack: "2",
                    actualTrack: "2"
                )
            ]
        )
        
        return GTFSRTTestDataBuilder.createFeed(
            entities: [timesSquareVehicle, lTrainVehicle, tripUpdate]
        )
    }
}

// MARK: - Test Assertions

/// Custom test assertions for transit-specific testing
struct TransitAssertions {
    
    /// Asserts that a train position has valid data
    static func assertValidTrainPosition(_ position: TrainPosition) {
        #expect(!position.id.isEmpty, "Train position ID should not be empty")
        #expect(!position.tripId.isEmpty, "Trip ID should not be empty")
        #expect(!position.routeId.isEmpty, "Route ID should not be empty")
        #expect(!position.direction.isEmpty, "Direction should not be empty")
        #expect(!position.currentStatus.isEmpty, "Current status should not be empty")
    }
    
    /// Asserts that a GTFS-RT feed has valid structure
    static func assertValidGTFSRTFeed(_ feed: TransitRealtime_FeedMessage) {
        #expect(!feed.header.gtfsRealtimeVersion.isEmpty, "GTFS-RT version should be present")
        #expect(feed.header.timestamp > 0, "Timestamp should be positive")
        #expect(!feed.entity.isEmpty, "Feed should contain entities")
        
        for entity in feed.entity {
            #expect(!entity.id.isEmpty, "Entity ID should not be empty")
            #expect(
                entity.hasVehicle || entity.hasTripUpdate || entity.hasAlert,
                "Entity should have at least one data type"
            )
        }
    }
    
    /// Asserts that stop info has valid timing data
    static func assertValidStopInfo(_ stopInfo: StopInfo) {
        #expect(!stopInfo.stopId.isEmpty, "Stop ID should not be empty")
        
        if let arrival = stopInfo.arrivalTime, let departure = stopInfo.departureTime {
            #expect(departure >= arrival, "Departure should be after or equal to arrival")
        }
    }
    
    /// Asserts that NYC direction conversion is correct
    static func assertValidNYCDirection(_ direction: String) {
        let validDirections = ["N", "S", "E", "W", "Uptown/Bronx", "Downtown/Brooklyn"]
        #expect(validDirections.contains(direction), "Direction should be valid NYC direction")
    }
}

// MARK: - Performance Test Utilities

/// Utilities for performance testing
struct PerformanceTestUtils {
    
    /// Measures execution time of an async operation
    static func measureAsync<T>(
        operation: () async throws -> T
    ) async rethrows -> (result: T, duration: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try await operation()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        return (result, duration)
    }
    
    /// Creates a large GTFS-RT feed for performance testing
    static func createLargeGTFSRTFeed(entityCount: Int = 1000) -> TransitRealtime_FeedMessage {
        var entities: [TransitRealtime_FeedEntity] = []
        
        for i in 0..<entityCount {
            let entity = GTFSRTTestDataBuilder.createVehicleEntity(
                id: "perf-test-\(i)",
                tripId: "trip-\(i)",
                routeId: "4",
                trainId: "train-\(i)",
                currentStopId: "stop-\(i % 100)" // Cycle through 100 stops
            )
            entities.append(entity)
        }
        
        return GTFSRTTestDataBuilder.createFeed(entities: entities)
    }
}

// MARK: - Test Configuration

/// Configuration for test environments
struct TestConfiguration {
    static let defaultTimeout: TimeInterval = 5.0
    static let networkTimeout: TimeInterval = 10.0
    static let maxEntityCount = 1000
    static let testDataVersion = "2.0"
    
    /// Creates a test environment configuration
    static func createTestEnvironment() -> [String: Any] {
        return [
            "timeout": defaultTimeout,
            "network_timeout": networkTimeout,
            "max_entities": maxEntityCount,
            "gtfs_version": testDataVersion
        ]
    }
}