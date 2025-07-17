# WhichWay

A modern iOS application built with SwiftUI that provides real-time NYC subway tracking using Apple Maps and MTA's live GTFS data. Track trains, search stations, and navigate the subway system with ease.

## About This Project

WhichWay serves dual purposes as both a production iOS application and a testing environment for AI-powered development tools:

### Production iOS App
A fully functional NYC subway tracking application built with modern SwiftUI architecture, real-time MTA data integration, and Apple Maps.

### AI Development Testing
This repository also serves as an excellent playground for testing and experimenting with **Claude Code Actions** and automated AI agent tasking. It provides a real-world iOS codebase to:

- Test AI-powered code generation and modification capabilities
- Experiment with automated development workflows  
- Explore how AI can enhance iOS development productivity
- Learn and practice with Claude Code Actions in a practical setting

The codebase offers complexity suitable for testing various AI development scenarios while maintaining clean, modern iOS development patterns.

## Features

- **Real-time Train Tracking**: Live positions of NYC subway trains using MTA's GTFS-Realtime data
- **Interactive Map**: Apple Maps integration with smooth navigation and search capabilities
- **Station Search**: Real-time filtering and search of subway stations
- **Route Visualization**: Display subway routes and polylines on the map
- **Offline Support**: SwiftData persistence for offline access to station data
- **Modern UI**: Clean SwiftUI interface with smooth animations and transitions

## Architecture

WhichWay follows modern iOS development patterns:

- **SwiftUI**: Declarative user interface framework
- **SwiftData**: Core Data replacement for persistent storage
- **MapKit**: Apple Maps integration for map rendering
- **MVVM Pattern**: Clean separation of concerns with ViewModels
- **Dependency Injection**: Testable architecture with protocol-based dependencies
- **Protocol Buffers**: Efficient parsing of GTFS real-time data

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
