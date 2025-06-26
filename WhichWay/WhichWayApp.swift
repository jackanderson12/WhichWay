//
//  WhichWayApp.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/15/25.
//

import SwiftUI
import SwiftData

@main
struct WhichWayApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(
            for: [
                SubwayRoute.self,
                SubwayStation.self,
                SubwayRoutePolyline.self
            ]
        )
    }
}


