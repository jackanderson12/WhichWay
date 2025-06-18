//
//  MapViewController.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/18/25.
//

import GoogleMaps
import UIKit

class MapViewController: UIViewController {

  let map =  GMSMapView()
  var isAnimating: Bool = false

  override func loadView() {
    super.loadView()
    self.view = map
  }
}

