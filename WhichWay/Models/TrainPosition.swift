//
//  TrainPosition.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/16/25.
//

import Foundation
import CoreLocation

struct TrainPosition: Identifiable {
    let id: String
    let coordinate: CLLocationCoordinate2D
}

