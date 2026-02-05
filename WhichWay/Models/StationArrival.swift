//
//  StationArrival.swift
//  WhichWay
//
//  Created by Jack Anderson on 2/5/26.
//

import Foundation

struct StationArrival: Identifiable {
    let id: String
    let routeId: String
    let routeShortName: String
    let routeColor: String
    let routeTextColor: String
    let direction: String      // "N" or "S"
    let directionLabel: String // "Uptown/Bronx" or "Downtown/Brooklyn"
    let arrivalTime: Date
    let tripId: String

    var minutesAway: Int {
        max(0, Int(arrivalTime.timeIntervalSinceNow / 60))
    }

    var arrivalDescription: String {
        let mins = minutesAway
        if mins == 0 { return "Now" }
        return "\(mins) min"
    }
}
