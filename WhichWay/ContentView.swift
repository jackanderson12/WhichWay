//
//  ContentView.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/15/25.
//

import SwiftUI
import GoogleMaps

struct ContentView: View {
    
    @StateObject var viewModel = MapViewModel()
    @State private var trains: [TrainPosition] = []
    
    /// State for markers displayed on the map for each city in `cities`
    @State var markers: [GMSMarker] = []

    @State var zoomInCenter: Bool = false
    @State var expandList: Bool = false
    @State var selectedMarker: GMSMarker?
    @State var yDragTranslation: CGFloat = 0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                // Map
                let diameter = zoomInCenter ? geometry.size.width : (geometry.size.height * 2)
                MapViewControllerBridge(markers: $markers, selectedMarker: $selectedMarker, onAnimationEnded: {
                    self.zoomInCenter = true
                }, mapViewWillMove: { (isGesture) in
                    guard isGesture else { return }
                    self.zoomInCenter = false
                })
                .clipShape(
                    Circle()
                        .size(
                            width: diameter,
                            height: diameter
                        )
                        .offset(
                            CGPoint(
                                x: (geometry.size.width - diameter) / 2,
                                y: (geometry.size.height - diameter) / 2
                            )
                        )
                )
                .background(Color(red: 254.0/255.0, green: 1, blue: 220.0/255.0))
            }
        }
        .task {
            trains = viewModel.trainPositions
        }
    }
}

#Preview {
    ContentView()
}
