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

// Date will be constructed in database --> server side


class InterfaceController: WKInterfaceController, CLLocationManagerDelegate{
    
    var saveUrl: URL?
    
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
        print(lat)
        print(long)
        
        let request = NSMutableURLRequest(url: NSURL(string: "http://147.46.242.219/addgps3.php")! as URL)
        request.httpMethod = "POST"
        let postString = "a=\(lat)&b=\(long)"
        request.httpBody = postString.data(using: .utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if error != nil {
                print("error=\(error)")
                return
            }
            
            print("response = \(response)")
            
            let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            print("responseString = \(responseString)")
        }
        
        task.resume()
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
    
    
    // when button clicked label is shown
    @IBAction func btnPressed() {
        
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
        
        
        /**
        let fileManager = FileManager.default
        let container = fileManager.containerURL(forSecurityApplicationGroupIdentifier:"group.com.project.BullyDetection")
        
        let fileName = "audioFile.wav"
        
        saveUrl = container?.appendingPathComponent(fileName)
        
        
        let duration = TimeInterval(10)
        let recordOptions = [WKAudioRecorderControllerOptionsMaximumDurationKey : duration]
        
        presentAudioRecorderController(withOutputURL: saveUrl! as URL, preset: .narrowBandSpeech, options: recordOptions, completion: { saved, error in
            
            if let err = error {
                print(err)
            }
            
            if saved {
               // self.playBtn.setEnabled(true)
                //var tmp = self.saveUrl?.absoluteString
                //print("Test")
                //print(tmp)
                
            }
            
            let audioFile = NSData(contentsOf: self.saveUrl as! URL)
            print(audioFile)
            
        })
         */
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
                
                
                let request = NSMutableURLRequest(url: NSURL(string: "http://147.46.242.219/addheartrate2.php")! as URL)
                request.httpMethod = "POST"
                let postString = "a=\(value)"
                request.httpBody = postString.data(using: .utf8)
                
                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if error != nil {
                        print("error=\(error)")
                        return
                    }
                    
                    print("response = \(response)")
                    
                    let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                    print("responseString = \(responseString)")
                }
                
                task.resume()
                
                print("This line is executed!")
                print(String(UInt16(value)))
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
