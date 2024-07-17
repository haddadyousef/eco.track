import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    private var locationManager: CLLocationManager
    private var onSpeedUpdate: ((Double) -> Void)?
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation(onSpeedUpdate: @escaping (Double) -> Void) {
        self.onSpeedUpdate = onSpeedUpdate
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            print("Location permission not determined.")
        case .restricted, .denied:
            print("Location permission restricted or denied.")
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location permission granted.")
            locationManager.startUpdatingLocation()
        @unknown default:
            print("Unknown location authorization status.")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            print("Current location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
            
            // Calculate speed in meters per second
            let speedInMetersPerSecond = location.speed
            
            // Convert speed to miles per hour
            let speedInMilesPerHour = speedInMetersPerSecond * 2.23694
            
            // Check for a valid speed value
            if speedInMetersPerSecond >= 0 {
                print("Current speed: \(speedInMilesPerHour) mph")
                onSpeedUpdate?(speedInMilesPerHour)
            } else {
                print("Speed data is not available")
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }
}
