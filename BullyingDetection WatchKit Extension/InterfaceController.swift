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
    var movement = ""
    
    var manualLat: Double = 0.0
    var manualLong: Double = 0.0
    var heartRateVal: Double = 0.0
    var prev_grav_z: Double = 0.0
    var prev_acc_z: Double = 0.0
    var grav_x:Double = 0.0
    var grav_y:Double = 0.0
    var grav_z:Double = 0.0
    var acc_x:Double = 0.0
    var acc_y:Double = 0.0
    var acc_z:Double = 0.0
    
    var sendOrNot:Bool = false
    
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
        
        motionManager.deviceMotionUpdateInterval = 0.5
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLoc =  locations[0]
        let lat = currentLoc.coordinate.latitude
        let long = currentLoc.coordinate.longitude
        
        manualLat = lat
        manualLong = long
       
        /**
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
        
        */
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
                self.grav_x = (deviceMotion?.gravity.x)!
                self.grav_y = (deviceMotion?.gravity.y)!
                self.grav_z = (deviceMotion?.gravity.z)!
                self.gravityStr = String(format: "grav_x: %.2f, grav_y: %.2f, grav_z: %.2f" ,
                                         self.grav_x,
                                         self.grav_y,
                                         self.grav_z)
                
                if self.prev_grav_z == 0.0 {
                    self.prev_grav_z = self.grav_z
                    self.sendOrNot = true
                }
                else{
                    if (self.grav_z - self.prev_grav_z) <= -0.25{
                        //print("Gravity: ",self.grav_z, self.prev_grav_z)
                        self.sendOrNot = true
                    }
                    else{
                        self.sendOrNot = false
                    }
                    self.prev_grav_z = self.grav_z
                }
               //self.sendData(x: self.gravityStr)
              // print(self.gravityStr)
                
                self.acc_x = (deviceMotion?.userAcceleration.x)!
                self.acc_y = (deviceMotion?.userAcceleration.y)!
                self.acc_z = (deviceMotion?.userAcceleration.z)!
                self.userAccelerStr = String(format: "acc_x: %.2f, acc_y: %.2f, acc_z: %.2f" ,
                                             self.acc_x,
                                             self.acc_y,
                                             self.acc_z)
                
                if (self.acc_z - self.prev_acc_z) <= -0.2{
                    //print("Accelero_z: ",self.acc_z, self.prev_acc_z)
                    self.sendOrNot = true
                }
                else{
                    self.sendOrNot = false
                }
                self.prev_acc_z = self.acc_z
                
                self.rotationRateStr = String(format: "rota_x: %.2f, rota_y: %.2f, rota_z: %.2f" ,
                                              (deviceMotion?.rotationRate.x)!,
                                              (deviceMotion?.rotationRate.y)!,
                                              (deviceMotion?.rotationRate.z)!)
                
               //self.sendData(x: self.rotationRateStr)
                
               //print(self.rotationRateStr)
                
                
                self.attitudeStr = String(format: "atti_roll: %.1f, atti_pitch: %.1f, atti_yaw: %.1f" ,
                                          (deviceMotion?.attitude.roll)!,
                                          (deviceMotion?.attitude.pitch)!,
                                          (deviceMotion?.attitude.yaw)!)
                
               //self.sendData(x: self.attitudeStr)
                
                //print(self.attitudeStr)
                
                //self.movement = self.gravityStr + self.userAccelerStr + self.rotationRateStr + self.attitudeStr
                if self.sendOrNot{
                    print("I am student. I need help!")
                    self.movement = "\(self.gravityStr), \(self.userAccelerStr), \(self.rotationRateStr), \(self.attitudeStr), \("_1")"
                }
                else{
                    self.movement = "\(self.gravityStr), \(self.userAccelerStr), \(self.rotationRateStr), \(self.attitudeStr), \("_0")"
                }
                //print(self.movement)
                self.sendOrNot = false
            }
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        motionManager.stopDeviceMotionUpdates()
    }
   
    /**
    func sendData(x:String){
        let request = NSMutableURLRequest(url: NSURL(string: "http://147.46.242.219/addgyro2.php")! as URL)
        request.httpMethod = "POST"
        let postString = "a=\(x)"
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
 
*/
   /**
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
*/
    
    // generate a short unique id
    struct ShortCodeGenerator {
        
        private static let base62chars = [Character]("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz")
        private static let maxBase : UInt32 = 62
        
        static func getCode(withBase base: UInt32 = maxBase, length: Int) -> String {
            var code = ""
            for _ in 0..<length {
                let random = Int(arc4random_uniform(min(base, maxBase)))
                code.append(base62chars[random])
            }
            return code
        }
    }
    
    
    // Getting the address from longitude and latitude
    func getAddressFromLatLon(pdblLatitude: String, withLongitude pdblLongitude: String) {
        var center : CLLocationCoordinate2D = CLLocationCoordinate2D()
        let lat: Double = Double("\(pdblLatitude)")!
        //21.228124
        let lon: Double = Double("\(pdblLongitude)")!
        //72.833770
        let ceo: CLGeocoder = CLGeocoder()
        center.latitude = lat
        center.longitude = lon
        
        let loc: CLLocation = CLLocation(latitude:center.latitude, longitude: center.longitude)
        
        
        ceo.reverseGeocodeLocation(loc, completionHandler:
            {(placemarks, error) in
                if (error != nil)
                {
                    //print("reverse geodcode fail: \(error!.localizedDescription)")
                }
                let pm = placemarks! as [CLPlacemark]
                
                if pm.count > 0 {
                    let pm = placemarks![0]
                    //print(pm.country)
                    //print(pm.locality)
                    //print(pm.subLocality)
                    //print(pm.thoroughfare)
                    //print(pm.postalCode)
                    //print(pm.subThoroughfare)
                    var addressString : String = ""
                    if pm.subLocality != nil {
                        addressString = addressString + pm.subLocality! + ", "
                    }
                    if pm.thoroughfare != nil {
                        addressString = addressString + pm.thoroughfare! + ", "
                    }
                    if pm.locality != nil {
                        addressString = addressString + pm.locality! + ", "
                    }
                    if pm.country != nil {
                        addressString = addressString + pm.country! + ", "
                    }
                    if pm.postalCode != nil {
                        addressString = addressString + pm.postalCode! + " "
                    }
                    
                    
                    //print(addressString)
                }
        })
        
    }
    
    
    @IBAction func manualBtnPressed() {
        // manual reporting functionality
        // generating 6 character long unique id
        
        let uniqueId = ShortCodeGenerator.getCode(length: 6)
        let txtMsg = "I am student \(uniqueId). I need help!"
        
       
        // Getting the address
        
        if manualLat != 0.0 && manualLong != 0.0 {
        var latStr = String(format:"%.2f",manualLat)
        var longStr = String(format:"%.2f",manualLong)
        getAddressFromLatLon(pdblLatitude: latStr, withLongitude: longStr)
        let request = NSMutableURLRequest(url: NSURL(string: "http://147.46.242.219/addmanual.php")! as URL)
        request.httpMethod = "POST"
        let postString = "a=\(manualLat)&b=\(manualLong)&c=\(txtMsg)"
        //print(txtMsg)
        request.httpBody = postString.data(using: .utf8)
        
   
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if error != nil {
                //print("error=\(error)")
                return
            }
            
            //print("response = \(response)")
            
            let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
            //print("responseString = \(responseString)")
        }
        
        task.resume()
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
            //print(date)
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
    /**
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
                
                //print("Type of value is +\(type(of:value))")
                
                if value == 100.0 {
                    var studentId = ShortCodeGenerator.getCode(length: 6)
                    let txtMsg = "I am student \(studentId). I need help!"
                    print("AutomaticMsg: I am student \(txtMsg)")
                }
                
                let request = NSMutableURLRequest(url: NSURL(string: "http://147.46.242.219/addall.php")! as URL)
                request.httpMethod = "POST"
                //print(self.movement)
                //let randomStr = 42.0
                let postString = "gps_x=\(self.manualLat)&gps_y=\(self.manualLong)&a=\(self.movement)&hr=\(value)"
                //print(postString)
                request.httpBody = postString.data(using: .utf8)
                
                let task = URLSession.shared.dataTask(with: request as URLRequest) {
                    data, response, error in
                    
                    if error != nil {
                        //print("error=\(error)")
                        return
                    }
                    
                    //print("response = \(response)")
                    
                    let responseString = NSString(data: data!, encoding: String.Encoding.utf8.rawValue)
                    //print("responseString = \(responseString)")
                }
                
                task.resume()
                
                //print("This line is executed!")
                //print(String(UInt16(value)))
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
