import Foundation
import CoreLocation
import Combine
import UIKit

class CompassService: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    
    @Published var heading: Double = 0.0
    @Published var direction: String = "N"
    @Published var isCalibrating: Bool = false
    
    static let shared = CompassService()
    
    private override init() {
        super.init()
        setupLocationManager()
        observeOrientationChanges()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.headingFilter = 1 // Update when heading changes by 1 degree
        updateHeadingOrientation()
    }
    
    private func observeOrientationChanges() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleOrientationChange),
            name: UIDevice.orientationDidChangeNotification,
            object: nil
        )
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
    
    @objc private func handleOrientationChange() {
        updateHeadingOrientation()
    }
    
    private func updateHeadingOrientation() {
        // Map device orientation to heading orientation for accurate results
        switch UIDevice.current.orientation {
        case .portrait:
            locationManager.headingOrientation = .portrait
        case .portraitUpsideDown:
            locationManager.headingOrientation = .portraitUpsideDown
        case .landscapeLeft:
            locationManager.headingOrientation = .landscapeLeft
        case .landscapeRight:
            locationManager.headingOrientation = .landscapeRight
        default:
            locationManager.headingOrientation = .portrait
        }
    }
    
    func startUpdates() {
        guard CLLocationManager.headingAvailable() else {
            print("Compass not available on this device")
            return
        }
        // Check authorization status without blocking the main thread
        let status = locationManager.authorizationStatus
        if status == .notDetermined {
            // Request permission asynchronously
            DispatchQueue.main.async { [weak self] in
                self?.locationManager.requestWhenInUseAuthorization()
            }
        } else {
            startAuthorizedUpdates()
        }
    }
    
    private func startAuthorizedUpdates() {
        // Start location updates for true heading (uses GPS + compass)
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
        // Start heading updates
        locationManager.startUpdatingHeading()
    }
    
    func stopUpdates() {
        locationManager.stopUpdatingHeading()
        locationManager.stopUpdatingLocation()
    }
    
    private func getDirectionString(from heading: Double) -> String {
        // Normalize heading to 0-360 range
        let normalizedHeading = heading.truncatingRemainder(dividingBy: 360)
        let positive = normalizedHeading < 0 ? normalizedHeading + 360 : normalizedHeading
        
        switch positive {
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
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startAuthorizedUpdates()
        case .denied, .restricted:
            print("Location authorization denied or restricted; heading may be unavailable")
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        // Use trueHeading if available (more accurate), otherwise use magneticHeading
        let heading = newHeading.trueHeading >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        
        // Update the published properties on the main thread
        DispatchQueue.main.async {
            // Smooth out the heading changes
            let difference = abs(self.heading - heading)
            
            // Handle the 360/0 degree boundary
            if difference > 180 {
                // We're crossing the 360/0 boundary
                if self.heading > heading {
                    self.heading = heading
                } else {
                    self.heading = heading
                }
            } else {
                // Normal update
                self.heading = heading
            }
            
            self.direction = self.getDirectionString(from: heading)
            
            // Calibration is needed when headingAccuracy is negative
            self.isCalibrating = newHeading.headingAccuracy < 0
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Location updates help improve true heading accuracy
        // No need to process the location data, just having updates helps the compass
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location/Compass error: \(error.localizedDescription)")
        
        if let error = error as? CLError {
            switch error.code {
            case .headingFailure:
                // Handle compass calibration needed
                DispatchQueue.main.async {
                    self.isCalibrating = true
                }
            case .denied, .locationUnknown:
                // Handle location permission issues
                print("Location services denied or unavailable")
            default:
                break
            }
        }
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        // Return true to allow iOS to show the figure-8 calibration screen
        return true
    }
}
