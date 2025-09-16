import SwiftUI
import GoogleMaps
import UIKit

struct GoogleMapsView: UIViewRepresentable {
    @Binding var coordinate: CLLocationCoordinate2D
    var markers: [GMSMarker]
    
    func makeUIView(context: Context) -> GMSMapView {
        let camera = GMSCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: 15.0)
        let mapView = GMSMapView(frame: .zero, camera: camera)
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: GMSMapView, context: Context) {
        mapView.clear()
        mapView.animate(to: GMSCameraPosition.camera(withLatitude: coordinate.latitude, longitude: coordinate.longitude, zoom: 15.0))
        
        for marker in markers {
            // Configure marker appearance
            marker.appearAnimation = .pop
            marker.map = mapView
            
            // Show info window by default to display address
            if let firstMarker = markers.first, marker == firstMarker {
                mapView.selectedMarker = marker
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, GMSMapViewDelegate {
        var parent: GoogleMapsView
        
        init(_ parent: GoogleMapsView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
            // Create custom info window with address text
            let infoWindow = UIView(frame: CGRect(x: 0, y: 0, width: 250, height: 70))
            infoWindow.backgroundColor = UIColor.white
            infoWindow.layer.cornerRadius = 8
            infoWindow.layer.shadowColor = UIColor.black.cgColor
            infoWindow.layer.shadowOpacity = 0.3
            infoWindow.layer.shadowOffset = CGSize(width: 0, height: 2)
            infoWindow.layer.shadowRadius = 4
            
            // Title label
            let titleLabel = UILabel(frame: CGRect(x: 10, y: 5, width: 230, height: 20))
            titleLabel.text = marker.title
            titleLabel.font = UIFont.boldSystemFont(ofSize: 14)
            
            // Snippet label (address)
            let snippetLabel = UILabel(frame: CGRect(x: 10, y: 25, width: 230, height: 40))
            snippetLabel.text = marker.snippet
            snippetLabel.font = UIFont.systemFont(ofSize: 12)
            snippetLabel.numberOfLines = 2
            
            infoWindow.addSubview(titleLabel)
            infoWindow.addSubview(snippetLabel)
            
            return infoWindow
        }
    }
}

// Instead of conforming to Equatable directly, use a helper function
func areCoordinatesEqual(_ lhs: CLLocationCoordinate2D, _ rhs: CLLocationCoordinate2D) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}
