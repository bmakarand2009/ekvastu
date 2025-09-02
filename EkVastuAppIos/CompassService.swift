import Foundation
import CoreLocation
import Combine

class CompassService: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private let compassUpdateInterval: TimeInterval = 0.5
    
    @Published var heading: Double = 0.0
    @Published var direction: String = "N"
    @Published var isCalibrating: Bool = false
    
    static let shared = CompassService()
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.headingFilter = 1 // Update when heading changes by 1 degree
        locationManager.headingOrientation = .portrait
    }
    
    func startUpdates() {
        if CLLocationManager.headingAvailable() {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingHeading()
        } else {
            print("Compass not available on this device")
        }
    }
    
    func stopUpdates() {
        locationManager.stopUpdatingHeading()
    }
    
    private func getDirectionString(from heading: Double) -> String {
        switch heading {
        case 0..<22.5, 337.5...360:
            return "N"
        case 22.5..<67.5:
            return "NE"
        case 67.5..<112.5:
            return "E"
        case 112.5..<157.5:
            return "SE"
        case 157.5..<202.5:
            return "S"
        case 202.5..<247.5:
            return "SW"
        case 247.5..<292.5:
            return "W"
        case 292.5..<337.5:
            return "NW"
        default:
            return "N"
        }
    }
}

extension CompassService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Use trueHeading if it's valid, otherwise use magneticHeading
        let heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
        
        // Update the published properties on the main thread
        DispatchQueue.main.async {
            self.heading = heading
            self.direction = self.getDirectionString(from: heading)
            self.isCalibrating = newHeading.headingAccuracy < 0
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Compass error: \(error.localizedDescription)")
        
        if let error = error as? CLError, error.code == .headingFailure {
            // Handle compass calibration needed
            DispatchQueue.main.async {
                self.isCalibrating = true
            }
        }
    }
}
