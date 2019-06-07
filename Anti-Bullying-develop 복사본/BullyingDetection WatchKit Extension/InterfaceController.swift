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
import AVFoundation
import CoreMotion



let hrType:HKQuantityType = HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!

// Date will be constructed in database --> server side


class InterfaceController: WKInterfaceController, CLLocationManagerDelegate,AVAudioRecorderDelegate{
    
    var saveUrl: URL?
    
    // to conduct permission to retrieve location data
    var locationManager: CLLocationManager = CLLocationManager()
    // Outlets for testing
    @IBOutlet weak var button: WKInterfaceButton!
    @IBOutlet weak var furtherSigLabels: WKInterfaceLabel!
    var recordingSession : AVAudioSession!
    var audioRecorder : AVAudioRecorder!
    var settings = [String : Any]()
    
    // distinguish start recording heartbeat
    var isRecording = false
    
    //For workout session
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var currentQuery: HKQuery?
    var filename: String?
    let motionManager = CMMotionManager()
    let queue = OperationQueue()
    var gravityStr = ""
    var userAccelerStr = ""
    var rotationRateStr = ""
    var attitudeStr = ""
    
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
        
        recordingSession = AVAudioSession.sharedInstance()
        
        do{
            try recordingSession.setCategory(AVAudioSession.Category.playAndRecord)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission(){[unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed{
                        print("Allow")
                    } else{
                        print("Don't Allow")
                    }
                }
            }
        }
        catch{
            print("failed to record!")
        }
        // Configure interface objects here.
        
        // Audio Settings
        
        settings = [
            AVFormatIDKey:Int(kAudioFormatLinearPCM),
            AVSampleRateKey:44100.0,
            AVNumberOfChannelsKey:1,
            AVLinearPCMBitDepthKey:8,
            AVLinearPCMIsFloatKey:false,
            AVLinearPCMIsBigEndianKey:false,
            AVEncoderAudioQualityKey:AVAudioQuality.max.rawValue
            
        ]
         motionManager.deviceMotionUpdateInterval = 1
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLoc =  locations[0]
        let lat = currentLoc.coordinate.latitude
        let long = currentLoc.coordinate.longitude
        print(lat)
        print(long)
        
        let request = NSMutableURLRequest(url: NSURL(string: "http://147.46.242.219/addgps.php")! as URL)
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
        motionManager.startDeviceMotionUpdates(to: queue) { (deviceMotion: CMDeviceMotion?, error: Error?) in
            if error != nil {
                print("Encountered error: \(error!)")
            }
            if deviceMotion != nil {
                self.gravityStr = String(format: "X: %.2f Y: %.2f Z: %.2f" ,
                                         (deviceMotion?.gravity.x)!,
                                         (deviceMotion?.gravity.y)!,
                                         (deviceMotion?.gravity.z)!)
                
                self.sendData(x: "\(deviceMotion?.gravity.x)", y: "\(deviceMotion?.gravity.x)", z: "\(deviceMotion?.gravity.x)")
                print(self.gravityStr)
                
                self.userAccelerStr = String(format: "X2: %.2f Y: %.2f Z: %.2f" ,
                                             (deviceMotion?.userAcceleration.x)!,
                                             (deviceMotion?.userAcceleration.y)!,
                                             (deviceMotion?.userAcceleration.z)!)
                
                self.sendData(x: "\(deviceMotion?.userAcceleration.x)", y: "\(deviceMotion?.userAcceleration.y)", z: "\(deviceMotion?.userAcceleration.z)")
                print(self.userAccelerStr)
                
                self.rotationRateStr = String(format: "X3: %.2f Y: %.2f Z: %.2f" ,
                                              (deviceMotion?.rotationRate.x)!,
                                              (deviceMotion?.rotationRate.y)!,
                                              (deviceMotion?.rotationRate.z)!)
                
                self.sendData(x: "\(deviceMotion?.rotationRate.x)", y: "\(deviceMotion?.rotationRate.y)", z: "\(deviceMotion?.rotationRate.z)")
                
                print(self.rotationRateStr)
                
                
                self.attitudeStr = String(format: "r4: %.1f p: %.1f y: %.1f" ,
                                          (deviceMotion?.attitude.roll)!,
                                          (deviceMotion?.attitude.pitch)!,
                                          (deviceMotion?.attitude.yaw)!)
                
                self.sendData(x: "\(deviceMotion?.attitude.roll)", y: "\(deviceMotion?.attitude.pitch)", z: "\(deviceMotion?.attitude.yaw)")
                
                print(self.attitudeStr)
            }
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        motionManager.stopDeviceMotionUpdates()
    }
    
    func sendData(x:String, y:String, z:String){
        let request = NSMutableURLRequest(url: NSURL(string: "http://147.46.242.219/addgyro.php")! as URL)
        request.httpMethod = "POST"
        let postString = "a=\(x)&b=\(y)&c=\(z)"
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
   
    func getDocumentsDirectory() -> URL
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    func getFileUrl() -> URL
    {
        let filePath = getDocumentsDirectory().appendingPathComponent(filename!)
        return filePath
    }
    
    func startRecording(){
        let audioSession = AVAudioSession.sharedInstance()
        
        do{
            audioRecorder = try AVAudioRecorder(url: getFileUrl(),
                                                settings: settings)
            audioRecorder.delegate = self
            audioRecorder.prepareToRecord()
            audioRecorder.record(forDuration: 5.0)
            
        }
        catch {
            finishRecording(success: false)
        }
        
        do {
            try audioSession.setActive(true)
            audioRecorder.record()
        } catch {
        }
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil

        if success {
            print(success)
        } else {
            audioRecorder = nil
            print("Somthing Wrong.")
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
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
        
        
      // Here audio?
    
        if audioRecorder == nil {
            print("Pressed")
            filename = NSUUID().uuidString+".wav"
            self.startRecording()
            
            
        } else {
            let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
            let url = URL(fileURLWithPath: path)
            print("Filename\(filename!)")
            let pathPart = url.appendingPathComponent(filename!)
            let filePath = pathPart.path
            
            let request = NSMutableURLRequest(url: NSURL(string: "http://147.46.242.219/addsound.php")! as URL)
            request.httpMethod = "POST"
            let audioData = NSData(contentsOfFile: filePath)
            print("Result is\(getFileUrl().path)")
            print("Binary data printing")
            print(audioData)
            let postString = "a=\(audioData)"
            
            
            request.httpBody = postString.data(using: .utf8)
            
            let task = URLSession.shared.dataTask(with: request as URLRequest){
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
        
            print("Pressed2")
            self.finishRecording(success: true)
            
        }
        
        
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
                
                
                let request = NSMutableURLRequest(url: NSURL(string: "http://147.46.242.219/addheartrate.php")! as URL)
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
