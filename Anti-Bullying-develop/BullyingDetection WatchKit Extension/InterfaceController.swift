//
//  InterfaceController.swift
//  BullyingDetection WatchKit Extension
//
//  Created by Dung Ho and Jaeyoung Kim
//  Copyright © 2019 호탄융, 김재영. All rights reserved.
//

import WatchKit
import Foundation
import CoreLocation
import HealthKit

    
let hrType:HKQuantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!

// retrieve components of full date: date, day, time
extension Date{
    func getDate(date: String)->String?{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = date
        return dateFormatter.string(from: self)
        
    }
}


class InterfaceController: WKInterfaceController, CLLocationManagerDelegate{
    
    // primary detection signal --> heartrate
    
    struct HeartRateSignal: Codable{
        var bpm: Double
    }
    
    
    // preparing JSON
    struct AddBullySignals: Codable {
        var latitude: Double
        var longitude: Double
        let date: String
        let day: String
        let time: String
    }
    static var currentPos = [Double](repeating: 0, count:2)
    
    static var additionalSigs: AddBullySignals?
    
    // to conduct permission to retrieve location data
    var locationManager: CLLocationManager = CLLocationManager()
    // Outlets for testing
    @IBOutlet weak var button: WKInterfaceButton!
    @IBOutlet weak var furtherSigLabels: WKInterfaceLabel!
    
    // distinguish start recording heartbeat
    var isRecording = false
    
    //For workout session
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var currentQuery: HKQuery?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.requestLocation()
        
        // managing authorization
        let healthService:HealthDataService = HealthDataService()
        healthService.authorizeHealthKitAccess { (success, error) in
            if success {
                print("HealthKit authorization received.")
            } else {
                print("HealthKit authorization denied!")
                if error != nil {
                    print("\(String(describing: error))")
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLoc =  locations[0]
        let lat = currentLoc.coordinate.latitude
        let long = currentLoc.coordinate.longitude
        showLabel(latPos: lat, longPos: long)
        print(lat)
        print(long)
    }
    
    func locationManager(_: CLLocationManager, didFailWithError error: Error) {
        let err = CLError.Code(rawValue: (error as NSError).code)!
        switch err {
        case .locationUnknown:
            break
        default:
            print(err)
        }
    }
    
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func showLabel(latPos: Double, longPos: Double){

        // build JSON
        let time_Component = AddBullySignals(latitude: latPos, longitude: longPos, date:Date().getDate(date:"yyyy/MMMM/dd")!, day:Date().getDate(date:"EEEE")!, time:Date().getDate(date:"HH:mm a")!)
        print(time_Component)
        
        guard let jsonData = try? JSONEncoder().encode(time_Component) else{
            return
        }
        // test
        let jsonString = String(data: jsonData, encoding: .utf8)
        furtherSigLabels.setText(jsonString)
       //print(jsonString)
       
        // configuration of URL request
        let url = URL(string: "http://147.46.242.219/addsound.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // upload json file
        let task = URLSession.shared.uploadTask(with: request, from: jsonData) { data, response, error in
            if let error = error {
                print ("error: \(error)")
                return
            }
            guard let response = response as? HTTPURLResponse,
                (200...299).contains(response.statusCode) else {
                    print ("server error")
                    return
            }
            print("\(response.statusCode)")
            
            if let mimeType = response.mimeType,
                mimeType == "application/json",
                let data = data,
                let dataString = String(data: data, encoding: .utf8) {
                print ("got data: \(dataString)")
            }
        }
        task.resume()
    }

    
    // when button clicked label is shown
    @IBAction func btnPressed() {
        //showLabel()
        
        if(!isRecording){
            let stopTitle = NSMutableAttributedString(string: "Stop Recording")
            stopTitle.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.red], range: NSMakeRange(0, stopTitle.length))
            button.setAttributedTitle(stopTitle)
            isRecording = true
            startWorkout() //Start workout session/healthkit streaming
        }else{
            let exitTitle = NSMutableAttributedString(string: "Start Recording")
            exitTitle.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.red], range: NSMakeRange(0, exitTitle.length))
            button.setAttributedTitle(exitTitle)
            isRecording = false
            healthStore.end(session!)
            
        }
        
    }
    
}

extension InterfaceController: HKWorkoutSessionDelegate{
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            print(date)
            if let query = heartRateQuery(date){
                self.currentQuery = query
                healthStore.execute(query)
            }
        //Execute Query
        case .ended:
            //Stop Query
            healthStore.stop(self.currentQuery!)
            session = nil
        default:
            print("Unexpected state: \(toState)")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        //Do Nothing
    }
    
    func startWorkout(){
        // If a workout has already been started, do nothing.
        if (session != nil) {
            return
        }
        // Configure the workout session.
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .running
        workoutConfiguration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(configuration: workoutConfiguration)
            session?.delegate = self
        } catch {
            fatalError("Unable to create workout session")
        }
        
        healthStore.start(self.session!)
        //print("Start Workout Session")
    }
    
    func heartRateQuery(_ startDate: Date) -> HKQuery? {
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictEndDate)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates:[datePredicate])
        
        let heartRateQuery = HKAnchoredObjectQuery(type: hrType, predicate: predicate, anchor: nil, limit: Int(HKObjectQueryNoLimit)) { (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            //Do nothing
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            guard let samples = samples as? [HKQuantitySample] else {return}
            DispatchQueue.main.async {
                guard let sample = samples.first else { return }
                
                // after extraction of bpm value conversion to double
                let value = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                var heartRate_Student = HeartRateSignal(bpm: value)
                heartRate_Student.bpm = value
                
                // building json with heartrate
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                
                do {
                    let jsonData = try encoder.encode(heartRate_Student)
                    
                    if let jsonString = String(data: jsonData, encoding: .utf8) {
                        //print(jsonString)
                    }
                    
                    let url = URL(string: "http://147.46.242.219/addheartrate.php")!
                    var request = URLRequest(url: url)
                    request.httpMethod = "POST"
                    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                    
                    let task = URLSession.shared.uploadTask(with: request, from: jsonData) { data, response, error in
                        if let error = error {
                            print ("error: \(error)")
                            return
                        }
                        guard let response = response as? HTTPURLResponse,
                            (200...299).contains(response.statusCode) else {
                                print ("server error")
                                return
                        }
                        if let mimeType = response.mimeType,
                            mimeType == "application/json",
                            let data = data,
                            let dataString = String(data: data, encoding: .utf8) {
                            print ("got data: \(dataString)")
                        }
                    }
                    task.resume()
                } catch {
                    print(error.localizedDescription)
                }
                
                
                print("This line is executed!")
                print(String(UInt16(value)))
               // self.label.setText(String(UInt16(value))) //Update label
            }
            
        }
        
        return heartRateQuery
    }
    
}
class HealthDataService {
    internal let healthKitStore:HKHealthStore = HKHealthStore()
    
    init() {}
    
    func authorizeHealthKitAccess(_ completion: ((_ success:Bool, _ error:Error?) -> Void)!) {
        let typesToShare = Set([hrType])
        let typesToSave = Set([hrType])
        healthKitStore.requestAuthorization(toShare: typesToShare, read: typesToSave) { (success, error) in
            completion(success, error)
        }
    }
}

