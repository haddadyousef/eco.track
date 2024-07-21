import SpriteKit
import SwiftUI
import UIKit
import CoreLocation
import UserNotifications

class GameScene: SKScene, UITextFieldDelegate, CLLocationManagerDelegate {
    
    fileprivate var label: SKLabelNode?
    fileprivate var spinnyNode: SKShapeNode?
    var welcome = SKLabelNode()
    var startScreen = true
    var getStarted = SKLabelNode()
    var carLabel = SKLabelNode()
    var background = SKSpriteNode(imageNamed: "background")
    var homeButton: UIButton!
    
    var ecotrack = SKLabelNode()
    var viewLeaderboardButton = UIButton(type: .system)
    
    var myProgressButton = UIButton(type: .system)
    var myBadgesButton = UIButton(type: .system)
    var hostingController: UIHostingController<LeaderboardView>?
    
    
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
    
    // Leaderboard variables
    var leaderboardLabel: SKLabelNode!
    var userEmissions: Int = 0
    var otherUserEmissions = [Int]()
    
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
        super.didMove(to: view)
        
        // Setup welcome and get started labels
        welcome.text = "Welcome to your personal carbon accountant"
        welcome.zPosition = 2
        welcome.fontSize = 16
        welcome.position = CGPoint(x: 0, y: 250)
        welcome.fontColor = SKColor.white
        welcome.fontName = "AvenirNext-Bold"
        addChild(welcome)
        
        getStarted.text = "Get Started"
        getStarted.fontSize = 20
        getStarted.position = CGPoint(x: 0, y: 200)
        getStarted.fontColor = SKColor.white
        getStarted.zPosition = 2
        getStarted.fontName = "AvenirNext-Bold"
        addChild(getStarted)
        
        ecotrack.text = "EcoTrack"
        ecotrack.fontSize = 30
        ecotrack.position = CGPoint(x:0, y:-350)
        ecotrack.fontColor = SKColor.white
        ecotrack.zPosition = 2
        ecotrack.fontName = "AvenirNext-Bold"
        addChild(ecotrack)
        
        background.zPosition = 1
        background.position = CGPoint(x: 0, y: 0)
        addChild(background)
        
        homeButton = UIButton(type: .custom)
        let homeImage = UIImage(named: "EcoTracker")
        homeButton.setImage(homeImage, for: .normal)
        homeButton.addTarget(self, action: #selector(homeButtonTapped), for: .touchUpInside)
        homeButton.translatesAutoresizingMaskIntoConstraints = false
        
        if let view = self.view {
            view.addSubview(homeButton)
            
            NSLayoutConstraint.activate([
                homeButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                homeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
                homeButton.widthAnchor.constraint(equalToConstant: 50),
                homeButton.heightAnchor.constraint(equalTo: homeButton.widthAnchor, multiplier: homeImage!.size.height / homeImage!.size.width)
            ])
        }

            
            // Add tap gesture recognizer to the image view

        
        
        carLabel = self.childNode(withName: "carquestion") as! SKLabelNode
        carLabel.isHidden = true
        
        loadCSVFile()
        
        // Initialize LocationManager
        customLocationManager = LocationManager()
        customLocationManager.delegate = self
        
        // Request notification permission and schedule daily notifications
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
        
        // Setup leaderboard label
        leaderboardLabel = SKLabelNode()
        leaderboardLabel.fontSize = 20
        leaderboardLabel.fontColor = SKColor.black
        leaderboardLabel.position = CGPoint(x: 0, y: 100)
        leaderboardLabel.isHidden = true
        leaderboardLabel.zPosition = 2
        addChild(leaderboardLabel)
    }
    
    func showGetStartedScreen() {
        // Show the welcome and get started labels
        welcome.isHidden = false
        getStarted.isHidden = false
    }
    
    func endDrivingSession() {
        if customLocationManager.isDriving {
            let emissions = customLocationManager.calculateEmissions(distance: customLocationManager.totalDistance, duration: customLocationManager.totalDuration, carYear: carYear, carMake: carMake, carModel: carModel, carData: carData)
            print("Total emissions: \(emissions) grams")
            
            // Update UI or store emissions as needed
            userEmissions = Int(emissions)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let location = touch.location(in: self)
            
            if startScreen == true && getStarted.contains(location) {
                presentLocationPermissionAlert()
                welcome.isHidden = true
                getStarted.isHidden = true
                carLabel.isHidden = false
                carLabel.fontName = "AvenirNext-Bold"
                carLabel.zPosition = 2
                carLabel.fontColor = SKColor.white
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
        center.removeAllPendingNotificationRequests()  // Remove previous notifications if any
        
        // Create content for the notification
        let content = UNMutableNotificationContent()
        content.title = "Daily Carbon Emission Report"
        content.body = generateDailyReport()
        content.sound = .default
        
        // Create a trigger to fire the notification daily at a specific time
        var dateComponents = DateComponents()
        dateComponents.hour = 22  // 10 PM
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
        let totalEmissions = customLocationManager.calculateEmissions(distance: customLocationManager.totalDistance, duration: customLocationManager.totalDuration, carYear: carYear, carMake: carMake, carModel: carModel, carData: carData)
        let distanceInMiles = customLocationManager.totalDistance / 1609.34
        
        return "Today, you drove \(distanceInMiles) miles and your carbon emissions were \(totalEmissions) grams."
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
        confirmButton.setTitleColor(.white, for: .normal)
        confirmButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 20)
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
    
    @objc func confirmButtonTapped() {
        print("Confirmed car: \(carYear) \(carMake) \(carModel)")
        
        // Save the selected car information
        UserDefaults.standard.set(carYear, forKey: "carYear")
        UserDefaults.standard.set(carMake, forKey: "carMake")
        UserDefaults.standard.set(carModel, forKey: "carModel")
        
        // Hide the pickers and confirm button
        yearPickerView.isHidden = true
        makePickerView.isHidden = true
        modelPickerView.isHidden = true
        confirmButton.isHidden = true
        
        // Show the new buttons
        showNewButtons()
    }
    
    @objc func homeButtonTapped() {
        hostingController?.view.removeFromSuperview()
        hostingController = nil
        showNewButtons()

        
    }
    
    func showNewButtons() {
        // Create and configure the 'View Leaderboard' button
        
        viewLeaderboardButton.setTitle("View Leaderboard", for: .normal)
        viewLeaderboardButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 20)  // Set font
        viewLeaderboardButton.setTitleColor(.white, for: .normal)
        viewLeaderboardButton.addTarget(self, action: #selector(viewLeaderboardButtonTapped), for: .touchUpInside)
        viewLeaderboardButton.isHidden = false
        
        // Create and configure the 'My Progress' button
        
        myProgressButton.setTitle("My Progress", for: .normal)
        myProgressButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 20)  // Set font
        myProgressButton.setTitleColor(.white, for: .normal)
        myProgressButton.addTarget(self, action: #selector(myProgressButtonTapped), for: .touchUpInside)
        myProgressButton.isHidden = false
        
        // Create and configure the 'My Badges' button
        
        myBadgesButton.setTitle("My Badges", for: .normal)
        myBadgesButton.addTarget(self, action: #selector(myBadgesButtonTapped), for: .touchUpInside)
        myBadgesButton.titleLabel?.font = UIFont(name: "AvenirNext-Bold", size: 20)
        myBadgesButton.setTitleColor(.white, for: .normal)
        myBadgesButton.isHidden = false
        
        // Add buttons to the view
        if let view = self.view {
            // Create a vertical stack view to hold the buttons
            let vStackView = UIStackView(arrangedSubviews: [viewLeaderboardButton, myProgressButton, myBadgesButton])
            vStackView.axis = .vertical
            vStackView.alignment = .center
            vStackView.distribution = .equalSpacing
            vStackView.spacing = 20
            
            vStackView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(vStackView)
            
            NSLayoutConstraint.activate([
                vStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                vStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                viewLeaderboardButton.widthAnchor.constraint(equalToConstant: 200),
                myProgressButton.widthAnchor.constraint(equalToConstant: 200),
                myBadgesButton.widthAnchor.constraint(equalToConstant: 200)
            ])
        }
    }

    @objc func viewLeaderboardButtonTapped() {
        let userEmissions = 0  // User's emissions are initially set to 0
        let randomEmissions1 = Int.random(in: 0...500)
        let randomEmissions2 = Int.random(in: 0...500)
        let randomEmissions3 = Int.random(in: 0...500)
        viewLeaderboardButton.isHidden = true
        myProgressButton.isHidden = true
        myBadgesButton.isHidden = true
        // Store other users' emissions for display
        let otherUserEmissions = [randomEmissions1, randomEmissions2, randomEmissions3]
        displayLeaderboard(userEmissions: userEmissions, otherUserEmissions: otherUserEmissions)
        homeButton.addTarget(self, action: #selector(homeButtonTapped), for: .touchUpInside)

    }

    @objc func myProgressButtonTapped() {
        viewLeaderboardButton.isHidden = true
        myProgressButton.isHidden = true
        myBadgesButton.isHidden = true
        print("My Progress button tapped")
        homeButton.addTarget(self, action: #selector(homeButtonTapped), for: .touchUpInside)

    }

    @objc func myBadgesButtonTapped() {
        viewLeaderboardButton.isHidden = true
        myProgressButton.isHidden = true
        myBadgesButton.isHidden = true
        print("My Badges button tapped")
        homeButton.addTarget(self, action: #selector(homeButtonTapped), for: .touchUpInside)

    }
    
    func displayLeaderboard(userEmissions: Int, otherUserEmissions: [Int]) {
        let leaderboardView = LeaderboardView(userEmissions: userEmissions, otherUserEmissions: otherUserEmissions)
        hostingController = UIHostingController(rootView: leaderboardView)
        
        if let view = self.view {
            hostingController?.view.frame = CGRect(x: 50, y: 300, width: 300, height: 200) // Adjust frame as needed
            hostingController?.view.backgroundColor = UIColor.clear
            
            view.addSubview(hostingController!.view)
            
            // Optionally animate the presentation
            hostingController?.view.alpha = 0
            UIView.animate(withDuration: 0.3) {
                self.hostingController?.view.alpha = 1
            }
        }
    }
    

    
    // Implement UITextFieldDelegate methods
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Handle the event when text field editing begins
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Handle the event when text field editing ends
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // Handle the event when return key is pressed
        textField.resignFirstResponder()
        return true
    }
}

// Conform to UIPickerViewDataSource and UIPickerViewDelegate
extension GameScene: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView {
        case yearPickerView:
            return years.count
        case makePickerView:
            return makes.count
        case modelPickerView:
            return models.count
        default:
            return 0
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView {
        case yearPickerView:
            return years[row]
        case makePickerView:
            return makes[row]
        case modelPickerView:
            return models[row]
        default:
            return nil
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView {
        case yearPickerView:
            carYear = years[row]
            makes = Array(Set(carData.filter { $0[0] == carYear }.map { $0[1] })).sorted()
            print("Selected Year: \(carYear), Available Makes: \(makes)")
            makePickerView.reloadAllComponents()
        case makePickerView:
            if row < makes.count {
                carMake = makes[row]
                print("Selected Make: \(carMake)")
                models = Array(Set(carData.filter { $0[0] == carYear && $0[1] == carMake }.map { $0[2] })).sorted()
                print("Available Models: \(models)")
                modelPickerView.reloadAllComponents()
            } else {
                print("Error: Selected row \(row) is out of bounds for makes array with count \(makes.count)")
            }
        case modelPickerView:
            if row < models.count {
                carModel = models[row]
                print("Selected Model: \(carModel)")
            } else {
                print("Error: Selected row \(row) is out of bounds for models array with count \(models.count)")
            }
        default:
            break
        }
    }
}
