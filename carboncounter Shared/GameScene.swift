import SpriteKit
import SwiftUI
import UIKit
import CoreLocation
import UserNotifications

class GameScene: SKScene, UITextFieldDelegate {

    fileprivate var label : SKLabelNode?
    fileprivate var spinnyNode : SKShapeNode?
    var welcome = SKLabelNode()
    var startScreen = true
    var getStarted = SKLabelNode()
    var carLabel = SKLabelNode()
    
    // UIPickerView declarations
    var yearPickerView: UIPickerView!
    var makePickerView: UIPickerView!
    var modelPickerView: UIPickerView!
    
    // UIStackView declaration
    var stackView: UIStackView!
    
    // Variables to store input
    var carYear: String = ""
    var carMake: String = ""
    var carModel: String = ""
    
    // UIButton declaration
    var confirmButton: UIButton!
    
    // Location Manager
    var locationManager: CLLocationManager!
    var customLocationManager: LocationManager!

    // Data for pickers
    var years = [String]()
    var makes = [String]()
    var models = [String]()
    var carData: [[String]] = []

    func loadCSVFile() {
        let csvFilePath = "/Users/neven/Downloads/caremissions.csv"

        do {
            let csvContent = try String(contentsOfFile: csvFilePath, encoding: .utf8)
            let rows = csvContent.components(separatedBy: "\n")

            for (index, row) in rows.enumerated() {
                if index == 0 { continue } // Skip header row
                let columns = row.components(separatedBy: ",")
                if columns.count == 4 {
                    carData.append(columns)
                }
            }

            years = Array(Set(carData.map { $0[0] })).sorted()

        } catch {
            print("Failed to read the CSV file: \(error)")
        }
    }

    override func didMove(to view: SKView) {
        // Existing setup code...

        welcome.text = "Welcome to your personal carbon accountant"
        welcome.fontSize = 20
        welcome.position = CGPoint(x: 0, y: 280)
        welcome.fontColor = SKColor.black
        getStarted.text = "Get Started"
        getStarted.fontSize = 20
        getStarted.position = CGPoint(x: 0, y: 200)
        getStarted.fontColor = SKColor.black
        carLabel = self.childNode(withName: "carquestion") as! SKLabelNode
        carLabel.isHidden = true
        startScreen = true
        addChild(getStarted)
        addChild(welcome)
        super.didMove(to: view)
        loadCSVFile()

        // Initialize LocationManager
        customLocationManager = LocationManager()
        requestNotificationPermission()
        scheduleDailyNotification()
        // Check for saved car information
        if let savedCarYear = UserDefaults.standard.string(forKey: "carYear"),
           let savedCarMake = UserDefaults.standard.string(forKey: "carMake"),
           let savedCarModel = UserDefaults.standard.string(forKey: "carModel") {
            // Use saved information
            carYear = savedCarYear
            carMake = savedCarMake
            carModel = savedCarModel
        } else {
            // No saved information, show the get started screen
            showGetStartedScreen()
        }
    }
    
    func showGetStartedScreen() {
        // Show the welcome and get started labels
        welcome.isHidden = false
        getStarted.isHidden = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            if startScreen == true && getStarted.contains(location) {
                presentLocationPermissionAlert()
                welcome.isHidden = true
                getStarted.isHidden = true
                carLabel.isHidden = false
                // Present alert for location permission
            }
        }
    }
    
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    func scheduleDailyNotification() {
        let center = UNUserNotificationCenter.current()

        // Create content for the notification
        let content = UNMutableNotificationContent()
        content.title = "Daily Carbon Emission Report"
        content.body = generateDailyReport()
        content.sound = .default

            // Create a trigger to fire the notification daily at a specific time
        var dateComponents = DateComponents()
        dateComponents.hour = 22  // 8 PM
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
            // Create the request
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

            // Schedule the request with the system
        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error.localizedDescription)")
            }
        }
    }

    func generateDailyReport() -> String {
        // Fetch daily and average carbon emissions (placeholder implementation)
        let dailyEmissions = getDailyCarbonEmissions()
        let averageEmissions = getAverageDailyCarbonEmissions()

        // Compare daily emissions with average emissions
        let comparison = dailyEmissions > averageEmissions ? "higher" : "lower"
        let difference = abs(dailyEmissions - averageEmissions)

        return "Your carbon emission for today is \(dailyEmissions) g/mile, which is \(difference) g/mile \(comparison) than your average daily emission of \(averageEmissions) g/mile."
    }

    func getDailyCarbonEmissions() -> Double {
        // Implement logic to calculate today's carbon emissions
        // Placeholder value
        return 120.0
    }

    func getAverageDailyCarbonEmissions() -> Double {
        // Implement logic to calculate the average daily carbon emissions
        // Placeholder value
        return 100.0
    }
    
    func presentLocationPermissionAlert() {
        let alert = UIAlertController(title: "Location Permission", message: "This app needs access to your location to provide a personalized experience.", preferredStyle: .alert)
        
        let allowAction = UIAlertAction(title: "Allow", style: .default) { _ in
            self.requestLocationPermission()  // Request location permission when user taps "Allow"
        }
        
        let denyAction = UIAlertAction(title: "Deny", style: .cancel) { _ in
            // Handle the denial if needed
            self.showCarInputFields()  // Show input fields even if location permission is denied
        }
        
        alert.addAction(allowAction)
        alert.addAction(denyAction)
        
        if let view = self.view, let viewController = view.window?.rootViewController {
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
    func requestLocationPermission() {
        customLocationManager.requestLocationPermission()
        showCarInputFields()  // Show input fields after requesting location permission
    }

    func showCarInputFields() {
        // Create and configure UIPickerViews
        yearPickerView = createPickerView()
        makePickerView = createPickerView()
        modelPickerView = createPickerView()
        
        // Create and configure UIStackView for horizontal layout
        let hStackView = UIStackView(arrangedSubviews: [yearPickerView, makePickerView, modelPickerView])
        hStackView.axis = .horizontal
        hStackView.alignment = .center
        hStackView.distribution = .fillEqually
        hStackView.spacing = 0
        
        // Set the frame and position of the hStackView
        hStackView.translatesAutoresizingMaskIntoConstraints = false  // Use Auto Layout
        view?.addSubview(hStackView)
        
        // Add constraints to center the hStackView
        hStackView.centerXAnchor.constraint(equalTo: view!.centerXAnchor).isActive = true
        hStackView.centerYAnchor.constraint(equalTo: view!.centerYAnchor).isActive = true
        hStackView.widthAnchor.constraint(equalTo: view!.widthAnchor, multiplier: 1).isActive = true
        hStackView.heightAnchor.constraint(equalToConstant: 150).isActive = true
        
        // Create and configure UIButton
        confirmButton = UIButton(type: .system)
        confirmButton.setTitle("Confirm", for: .normal)
        confirmButton.translatesAutoresizingMaskIntoConstraints = false  // Use Auto Layout
        confirmButton.addTarget(self, action: #selector(confirmButtonTapped), for: .touchUpInside)
        view?.addSubview(confirmButton)
        
        // Add constraints to position the confirmButton below the hStackView
        confirmButton.centerXAnchor.constraint(equalTo: view!.centerXAnchor).isActive = true
        confirmButton.topAnchor.constraint(equalTo: hStackView.bottomAnchor, constant: 20).isActive = true
        confirmButton.widthAnchor.constraint(equalToConstant: 100).isActive = true
        confirmButton.heightAnchor.constraint(equalToConstant: 30).isActive = true
        
        // Set the data source and delegate of the pickers
        yearPickerView.dataSource = self
        yearPickerView.delegate = self
        makePickerView.dataSource = self
        makePickerView.delegate = self
        modelPickerView.dataSource = self
        modelPickerView.delegate = self
    }
    
    func createPickerView() -> UIPickerView {
        let pickerView = UIPickerView()
        pickerView.translatesAutoresizingMaskIntoConstraints = false  // Use Auto Layout
        return pickerView
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let text: String
        if pickerView == yearPickerView {
            text = years[row]
        } else if pickerView == makePickerView {
            text = makes[row]
        } else {
            text = models[row]
        }
        return NSAttributedString(string: text, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10)])
    }
    
    @objc func confirmButtonTapped() {
        // Retrieve selected values from picker views
        carYear = years[yearPickerView.selectedRow(inComponent: 0)]
        carMake = makes[makePickerView.selectedRow(inComponent: 0)]
        carModel = models[modelPickerView.selectedRow(inComponent: 0)]
        
        // Save car information
        UserDefaults.standard.set(carYear, forKey: "carYear")
        UserDefaults.standard.set(carMake, forKey: "carMake")
        UserDefaults.standard.set(carModel, forKey: "carModel")
        
        // Concatenate car details into a single string
        let carName = "\(carYear) \(carMake) \(carModel)"
        
        // Print the input values (you can handle them as needed)
        print("Year: \(carYear), Make: \(carMake), Model: \(carModel), Car Name: \(carName)")
        
        // Remove pickers and button from view
        yearPickerView.removeFromSuperview()
        makePickerView.removeFromSuperview()
        modelPickerView.removeFromSuperview()
        confirmButton.removeFromSuperview()
        
        // Start updating location to track speed
        //customLocationManager.startUpdatingLocation(onSpeedUpdate: { speed in
            //print("Current speed: \(speed) mph")
        //})
    }

    func updateMakesAndModels() {
        if let selectedYearIndex = yearPickerView?.selectedRow(inComponent: 0) {
            let selectedYear = years[selectedYearIndex]
            let filteredMakes = carData.filter { $0[0] == selectedYear }.map { $0[1] }
            makes = Array(Set(filteredMakes)).sorted()

            if let selectedMakeIndex = makePickerView?.selectedRow(inComponent: 0), selectedMakeIndex < makes.count {
                let selectedMake = makes[selectedMakeIndex]
                let filteredModels = carData.filter { $0[0] == selectedYear && $0[1] == selectedMake }.map { $0[2] }
                models = Array(Set(filteredModels)).sorted()
            } else {
                models = []
            }

            makePickerView?.reloadAllComponents()
            modelPickerView?.reloadAllComponents()
        }
    }

}

extension GameScene: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == yearPickerView {
            return years.count
        } else if pickerView == makePickerView {
            return makes.count
        } else if pickerView == modelPickerView {
            return models.count
        }
        return 0
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == yearPickerView {
            return years[row]
        } else if pickerView == makePickerView {
            return makes[row]
        } else if pickerView == modelPickerView {
            return models[row]
        }
        return nil
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == yearPickerView {
            updateMakesAndModels()
        } else if pickerView == makePickerView {
            if let selectedYearIndex = yearPickerView?.selectedRow(inComponent: 0) {
                let selectedYear = years[selectedYearIndex]
                let selectedMake = makes[row]
                let filteredModels = carData.filter { $0[0] == selectedYear && $0[1] == selectedMake }.map { $0[2] }
                models = Array(Set(filteredModels)).sorted()
                modelPickerView.reloadAllComponents()
            }
        }
    }
}

extension GameScene: CLLocationManagerDelegate {
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
            print("Unknown authorization status.")
        }
    }
}
