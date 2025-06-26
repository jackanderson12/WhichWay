//
//  Routes.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/24/25.
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - Subway Route Models, Storing in Swift Data as information does not need to be updated as frequently
@Model
class SubwayRoute {
    var routeId: String
    var agencyId: String
    var routeShortName: String
    var routeLongName: String
    var routeDescription: String
    var routeUrl: String
    var routeColor: String?
    var routeTextColor: String?
    
    init(
        routeId: String,
        agencyId: String,
        routeShortName: String,
        routeLongName: String,
        routeDescription: String,
        routeUrl: String,
        routeColor: String?,
        routeTextColor: String?
    ) {
        self.routeId = routeId
        self.agencyId = agencyId
        self.routeShortName = routeShortName
        self.routeLongName = routeLongName
        self.routeDescription = routeDescription
        self.routeUrl = routeUrl
        self.routeColor = routeColor
        self.routeTextColor = routeTextColor
    }
}
