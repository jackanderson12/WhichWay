# WhichWay

A modern iOS application built with SwiftUI that provides real-time NYC subway tracking using Apple Maps and MTA's live GTFS data. Track trains, search stations, and navigate the subway system with ease.

## Features

- **Real-time Train Tracking**: Live positions of NYC subway trains using MTA's GTFS-Realtime data
- **Interactive Map**: Apple Maps integration with smooth navigation and search capabilities
- **Station Search**: Real-time filtering and search of subway stations
- **Route Visualization**: Display subway routes and polylines on the map
- **Offline Support**: SwiftData persistence for offline access to station data
- **Modern UI**: Clean SwiftUI interface with smooth animations and transitions

## Requirements

- **iOS**: 17.0+
- **Xcode**: 15.0+
- **Swift**: 5.9+
- **Platform**: iPhone and iPad

## Architecture

WhichWay follows modern iOS development patterns:

- **SwiftUI**: Declarative user interface framework
- **SwiftData**: Core Data replacement for persistent storage
- **MapKit**: Apple Maps integration for map rendering
- **MVVM Pattern**: Clean separation of concerns with ViewModels
- **Dependency Injection**: Testable architecture with protocol-based dependencies
- **Protocol Buffers**: Efficient parsing of GTFS real-time data

### Key Components

```
WhichWay/
├── Models/              # Data models for subway entities
├── Services/            # MTA data fetching and processing
├── ViewModels/          # Business logic and state management
├── Views/               # SwiftUI user interface components
└── Protos/              # GTFS Protocol Buffer definitions
```

## Apple Maps Integration

The app leverages Apple's MapKit framework to provide:

- **Native map rendering** with standard iOS map interactions
- **Custom annotations** for subway stations and train positions
- **Polyline overlays** for subway route visualization
- **Search integration** with MKLocalSearch for location services
- **Camera positioning** for optimal viewing of NYC subway system

## MTA Data Integration

WhichWay integrates with the Metropolitan Transportation Authority's real-time data:

### GTFS Static Data
- **Station information**: Names, coordinates, and route assignments
- **Route definitions**: Subway line colors, names, and patterns
- **Service schedules**: Regular service patterns and timing

### GTFS-Realtime Data
- **Vehicle positions**: Live train locations and movements
- **Trip updates**: Delay information and service alerts
- **Service alerts**: Disruptions and service changes

### Data Processing Pipeline
1. **Download** GTFS static data and real-time feeds
2. **Parse** Protocol Buffer formatted data
3. **Transform** into app-specific models
4. **Cache** in SwiftData for offline access
5. **Update** UI with real-time information

## Getting Started

### 1. Clone the Repository
```bash
git clone https://github.com/jackanderson12/WhichWay.git
cd WhichWay
```

### 2. Open in Xcode
```bash
open WhichWay.xcodeproj
```

### 3. Dependencies
The project uses Swift Package Manager for dependencies:
- **SwiftProtobuf**: Protocol Buffer parsing
- **Zip**: GTFS data extraction
- **GoogleMaps**: Enhanced mapping capabilities (optional)

Dependencies are automatically resolved when you open the project in Xcode.

### 4. Build and Run
1. Select a target device or simulator (iOS 17.0+)
2. Press `Cmd+R` to build and run
3. Allow location permissions when prompted for optimal experience

## Key Services

### MTAService
Handles all MTA data operations:
- Fetches GTFS static and real-time data
- Processes and parses Protocol Buffer feeds
- Manages data updates and caching

### StationNameResolver
Resolves station identifiers to human-readable names using GTFS static data.

### GTFSDataProcessor
Transforms raw GTFS data into app-specific models for UI consumption.

## Testing

The project includes comprehensive test coverage:

```bash
# Run unit tests
Cmd+U in Xcode

# Test files location
WhichWayTests/
├── MTAServiceTests.swift      # MTA data service tests
├── MapViewModelTests.swift    # ViewModel logic tests
└── TestUtilities.swift       # Test helpers and mocks
```

## Data Sources

- **MTA GTFS Static**: Station and route information
- **MTA GTFS-Realtime**: Live train positions and updates
- **Apple Maps**: Base map data and location services

## Privacy & Permissions

WhichWay requires the following permissions:
- **Location Services**: To center map on user's location (optional)
- **Network Access**: To fetch real-time MTA data

No personal data is collected or transmitted beyond Apple's standard MapKit usage.

## Development

### Project Structure
- **Dependency Injection**: Clean testable architecture
- **Protocol-based Design**: Interfaces for all services
- **SwiftData Models**: Persistent storage for offline support
- **Environment Configuration**: Separate configurations for development/production
