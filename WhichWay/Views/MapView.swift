//
//  MapView.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/15/25.
//

import SwiftUI
import GoogleMaps

struct MapView: UIViewRepresentable {
    @Binding var markers: [GMSMarker]
    @Binding var selectedMarker: GMSMarker?
    
    var onAnimationEnded: () -> ()
    
    private let gmsMapView = GMSMapView()
    private let defaultZoomLevel: Float = 10
    
    func makeUIView(context: Context) -> GMSMapView {
        // Create a GMSMapView centered around the city of NYC
        let sanFrancisco = CLLocationCoordinate2D(latitude: 41.7128, longitude: -74.0060)
        gmsMapView.camera = GMSCameraPosition.camera(withTarget: sanFrancisco, zoom: defaultZoomLevel)
        gmsMapView.delegate = context.coordinator
        gmsMapView.isUserInteractionEnabled = true
        return gmsMapView
    }
    
    func updateUIView(_ uiView: GMSMapView, context: Context) {
        markers.forEach { marker in
            marker.map = uiView
        }
        if let selectedMarker = selectedMarker {
            let camera = GMSCameraPosition.camera(withTarget: selectedMarker.position, zoom: defaultZoomLevel)
            print("Animating to position \(selectedMarker.position)")
            CATransaction.begin()
            CATransaction.setValue(NSNumber(floatLiteral: 5), forKey: kCATransactionAnimationDuration)
            gmsMapView.animate(with: GMSCameraUpdate.setCamera(camera))
            CATransaction.commit()
        }
    }
    
    func makeCoordinator() -> MapViewCoordinator {
        return MapViewCoordinator(self)
    }
    
    
    final class MapViewCoordinator: NSObject, GMSMapViewDelegate {
        var mapView: MapView
        
        init(_ mapView: MapView) {
            self.mapView = mapView
        }
        
        func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
            //      let marker = GMSMarker(position: coordinate)
            //      self.mapView.polygonPath.append(marker)
        }
        
        func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
            self.mapView.onAnimationEnded()
        }
        
    }
}


//#Preview {
//    MapView(markers: <#Binding<[GMSMarker]>#>, selectedMarker: <#Binding<GMSMarker?>#>, onAnimationEnded: <#() -> ()#>)
//}
