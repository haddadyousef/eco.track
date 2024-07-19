import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager
    var delegate: CLLocationManagerDelegate?
    var lastLocation: CLLocation?
    var totalDistance: CLLocationDistance = 0.0
    var totalDuration: TimeInterval = 0.0
    var isDriving = false
    var startDrivingDate: Date?

    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // Update every 10 meters
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }

    func startTrackingDriving() {
        isDriving = true
        startDrivingDate = Date()
        lastLocation = nil
        totalDistance = 0.0
        totalDuration = 0.0
    }

    func stopTrackingDriving() {
        isDriving = false
        startDrivingDate = nil
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard isDriving else { return }
        guard let newLocation = locations.last else { return }
        
        if let lastLocation = lastLocation {
            let distance = newLocation.distance(from: lastLocation)
            totalDistance += distance
            if let startDrivingDate = startDrivingDate {
                let duration = Date().timeIntervalSince(startDrivingDate)
                totalDuration += duration
            }
        }
        
        lastLocation = newLocation
        delegate?.locationManager?(manager, didUpdateLocations: locations)
        
        // Check if the user is likely in a car (speed > 25 mph)
        if newLocation.speed > 11.176 { // 25 mph in meters per second
            // Example threshold for car speed, adjust as needed
            print("User is likely in a car.")
        }
    }

    func processLocation(_ location: CLLocation) {
        guard isDriving else { return }

        if let lastLocation = lastLocation {
            let distance = location.distance(from: lastLocation)
            totalDistance += distance
            if let startDrivingDate = startDrivingDate {
                let duration = Date().timeIntervalSince(startDrivingDate)
                totalDuration += duration
            }
        }

        lastLocation = location
        delegate?.locationManager?(locationManager, didUpdateLocations: [location])

        // Check if the user is likely in a car (speed > 25 mph)
        if location.speed > 11.176 { // 25 mph in meters per second
            // Example threshold for car speed, adjust as needed
            print("User is likely in a car.")
        }
    }

    func startLocationUpdates() {
        locationManager.startUpdatingLocation()
    }

    func calculateEmissions(distance: Double, duration: TimeInterval, carYear: String, carMake: String, carModel: String, carData: [[String]]) -> Double {
        // Find car emissions data
        var emissionsPerMile = 0.0
        for car in carData {
            if car[0] == carYear && car[1] == carMake && car[2] == carModel, let emissions = Double(car[3]) {
                emissionsPerMile = emissions
                break
            }
        }
        
        // Convert distance to miles and calculate total emissions
        let distanceInMiles = distance / 1609.34
        let totalEmissions = emissionsPerMile * distanceInMiles
        
        return totalEmissions
    }

    // Other methods and properties...
}
