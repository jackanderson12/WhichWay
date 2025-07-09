# WhichWay Testing Suite

This directory contains comprehensive unit tests for the WhichWay NYC subway app, built using Swift Testing framework.

## Test Structure

### Test Files

- **`MTAServiceTests.swift`** - Tests for MTA data service functionality
- **`MapViewModelTests.swift`** - Tests for map view model and data processing
- **`TestUtilities.swift`** - Shared utilities and test data builders
- **`ProtocolBasedTestSetup.swift`** - Mock implementations and testable architecture

### Test Coverage

#### MTAService Tests
- GTFS-RT feed fetching and parsing
- Base data downloading and processing
- Error handling for network failures
- Thread safety with actor model
- API integration testing

#### MapViewModel Tests
- Real-time train position processing
- GTFS-RT data transformation
- NYC-specific extensions handling
- UI state management
- Error handling and recovery

#### Model Tests
- TrainPosition data structure validation
- StopInfo timing calculations
- Direction mapping and display names
- Station name extraction logic

## Testing Architecture

### Current Architecture Challenges

The current codebase has some testability limitations:

1. **Hard-coded Dependencies**: MTAService and MapViewModel use concrete dependencies
2. **Network Dependencies**: Tests currently hit real MTA APIs
3. **Mixed Concerns**: Data processing logic is embedded in view models

### Improved Architecture (Recommended)

The test suite includes a protocol-based architecture design that addresses these issues:

```swift
// Protocol-based dependency injection
class TestableMapViewModel: ObservableObject {
    init(
        mtaService: MTAServiceProtocol,
        dataProcessor: GTFSDataProcessorProtocol,
        stationResolver: StationNameResolverProtocol
    )
}
```

### Mock Implementations

#### MockMTAService
- Configurable responses and errors
- Call tracking for verification
- Realistic GTFS-RT data simulation
- Network delay simulation

#### MockGTFSDataProcessor
- Controlled data transformation
- Predictable train position generation
- Stop information processing
- Performance testing support

#### MockStationNameResolver
- Station ID to name mapping
- Coordinate lookup functionality
- NYC-specific station data

## Test Utilities

### GTFSRTTestDataBuilder
Creates realistic GTFS-RT feed data for testing:

```swift
let feed = GTFSRTTestDataBuilder.createFeed(
    entities: [
        GTFSRTTestDataBuilder.createVehicleEntity(
            id: "test-vehicle",
            routeId: "4",
            trainId: "4-1234"
        )
    ]
)
```

### NYCTransitTestData
Pre-built NYC subway scenarios:

```swift
let nycScenario = NYCTransitTestData.createNYCSubwayScenario()
// Contains realistic Times Square and Union Square train data
```

### TransitAssertions
Custom assertions for transit-specific validation:

```swift
TransitAssertions.assertValidTrainPosition(position)
TransitAssertions.assertValidGTFSRTFeed(feed)
```

## Running Tests

### Command Line
```bash
# Run all tests
swift test

# Run specific test suite
swift test --filter "MTAServiceTests"

# Run with verbose output
swift test --verbose
```

### Xcode
1. Open WhichWay.xcodeproj
2. Select WhichWayTests target
3. Press Cmd+U to run tests
4. View results in Test Navigator

## Test Data

### Sample GTFS-RT Data
Tests use realistic NYC subway data including:
- 4/5/6 train positions at Times Square
- L train movements through Union Square
- Trip updates with arrival predictions
- NYC-specific extensions (train IDs, directions)

### Performance Testing
Large dataset generation for performance validation:

```swift
let largeFeed = PerformanceTestUtils.createLargeGTFSRTFeed(entityCount: 1000)
let (result, duration) = await PerformanceTestUtils.measureAsync {
    return processor.processTrainPositions(from: largeFeed)
}
```

## Migration to Testable Architecture

### Step 1: Extract Protocols
Define service protocols for dependency injection:

```swift
protocol MTAServiceProtocol {
    func fetchFeed() async throws -> TransitRealtime_FeedMessage
    func fetchBaseData() async throws
}
```

### Step 2: Separate Data Processing
Extract GTFS processing logic:

```swift
class GTFSDataProcessor: GTFSDataProcessorProtocol {
    func processTrainPositions(from feed: TransitRealtime_FeedMessage) -> [TrainPosition]
}
```

### Step 3: Add Station Resolution
Create dedicated station name resolver:

```swift
class StationNameResolver: StationNameResolverProtocol {
    func resolveName(for stopId: String) -> String
}
```

### Step 4: Update View Models
Modify MapViewModel to accept dependencies:

```swift
class MapViewModel: ObservableObject {
    init(
        mtaService: MTAServiceProtocol = MTAService(),
        dataProcessor: GTFSDataProcessorProtocol = GTFSDataProcessor(),
        stationResolver: StationNameResolverProtocol = StationNameResolver()
    )
}
```

### Step 5: Configure App
Update WhichWayApp.swift for dependency injection:

```swift
@main
struct WhichWayApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(MapViewModel(
                    mtaService: MTAService(),
                    dataProcessor: GTFSDataProcessor(),
                    stationResolver: StationNameResolver()
                ))
        }
    }
}
```

## Benefits of Testable Architecture

### 1. **Fast Tests**
- No network dependencies
- Predictable mock responses
- Millisecond execution times

### 2. **Reliable Tests**
- Deterministic outcomes
- No flaky network failures
- Consistent test data

### 3. **Comprehensive Coverage**
- Test error scenarios easily
- Mock edge cases
- Verify all code paths

### 4. **Better Design**
- Clear separation of concerns
- Dependency injection
- Single responsibility principle

## Best Practices

### Test Organization
- Group related tests in suites
- Use descriptive test names
- Include setup and teardown
- Test both success and failure cases

### Mock Configuration
- Reset mocks between tests
- Configure realistic data
- Track method calls
- Simulate network delays

### Assertions
- Use specific assertions
- Test behavior, not implementation
- Verify state changes
- Check error conditions

### Performance
- Include performance tests
- Measure critical paths
- Test with large datasets
- Monitor memory usage

## Future Enhancements

### Integration Tests
- End-to-end scenarios
- Real MTA API testing
- SwiftData integration
- UI interaction testing

### Continuous Integration
- Automated test runs
- Code coverage reports
- Performance benchmarks
- Test result notifications

### Test Documentation
- Test case descriptions
- Expected behaviors
- Edge case coverage
- Performance requirements

## Troubleshooting

### Common Issues

1. **Actor Isolation Warnings**
   - Ensure @MainActor usage is correct
   - Use proper async/await patterns
   - Test actor isolation boundaries

2. **Memory Leaks**
   - Reset mocks between tests
   - Avoid retain cycles in closures
   - Use weak references appropriately

3. **Timing Issues**
   - Add proper async test delays
   - Use expectation patterns
   - Avoid race conditions

### Performance Issues
- Profile test execution times
- Optimize mock implementations
- Use lazy initialization
- Cache test data when appropriate

## Contributing

When adding new tests:
1. Follow existing naming conventions
2. Include both success and failure cases
3. Add performance tests for critical paths
4. Update documentation
5. Use provided test utilities
6. Follow protocol-based architecture patterns