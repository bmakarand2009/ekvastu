import SwiftUI
import GoogleMaps
import UIKit

struct GoogleMapsView: UIViewRepresentable {
    @Binding var coordinate: CLLocationCoordinate2D
    var markers: [GMSMarker]
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: 15.0)
        let mapView = GMSMapView.map(withFrame: .zero, camera: camera)
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.clear()
        mapView.animate(to: GMSCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: 15.0))
        
        for marker in markers {
            marker.map = mapView
        }
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}
