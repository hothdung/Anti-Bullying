/**
Testing class
for testing movement capturing
 Creator: Jaeyoung and Dung
*/

import WatchKit
import Foundation
import CoreMotion


class InterfaceController: WKInterfaceController {
    let motionManager = CMMotionManager()
    let queue = OperationQueue()
    var gravityStr = ""
    var userAccelerStr = ""
    var rotationRateStr = ""
    var attitudeStr = ""
    var num = ""
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        motionManager.deviceMotionUpdateInterval = 1
    }
    
    override func willActivate() {
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
                self.num = "10.0"
                self.sendData(x: self.num)
                print(self.num)
                //print(self.gravityStr)
                
                self.userAccelerStr = String(format: "X2: %.2f Y: %.2f Z: %.2f" ,
                                             (deviceMotion?.userAcceleration.x)!,
                                             (deviceMotion?.userAcceleration.y)!,
                                             (deviceMotion?.userAcceleration.z)!)
                //print(type(of:self.userAccelerStr))
               // self.sendData(x: "\(deviceMotion?.userAcceleration.x)", y: "\(deviceMotion?.userAcceleration.y)", z: "\(deviceMotion?.userAcceleration.z)")
                //self.sendData(x: "\(4.32)", y: "\(6.82)", z: "\(9.87)")
                 //self.sendData(x:self.userAccelerStr)
        
                //print(self.userAccelerStr)
                
                self.rotationRateStr = String(format: "X3: %.2f Y: %.2f Z: %.2f" ,
                                              (deviceMotion?.rotationRate.x)!,
                                              (deviceMotion?.rotationRate.y)!,
                                              (deviceMotion?.rotationRate.z)!)
                
               // self.sendData(x: "\(deviceMotion?.rotationRate.x)", y: "\(deviceMotion?.rotationRate.y)", z: "\(deviceMotion?.rotationRate.z)")
                
                //self.sendData(x:self.rotationRateStr)
                //print(self.rotationRateStr)
                //self.sendData(x: "\(3.43)", y: "\(9.02)", z: "\(5.37)")
                
                self.attitudeStr = String(format: "r4: %.1f p: %.1f y: %.1f" ,
                                          (deviceMotion?.attitude.roll)!,
                                          (deviceMotion?.attitude.pitch)!,
                                          (deviceMotion?.attitude.yaw)!)
                
                
                //self.sendData(x: "\(deviceMotion?.attitude.roll)", y: "\(deviceMotion?.attitude.pitch)", z: "\(deviceMotion?.attitude.yaw)")
                
                //self.sendData(x: "\(9.62)", y: "\(8.92)", z: "\(9.28)")
                //self.sendData(x: self.attitudeStr)
                //print(self.attitudeStr)
                
                
                
                //print(String(format: "%.2f", (deviceMotion?.rotationRate.x)!))
                //print(String(format: "%.2f", (deviceMotion?.rotationRate.y)!))
                //print(String(format: "%.2f", (deviceMotion?.rotationRate.z)!))
            }
        }
        
    }
    
    func sendData(x:String){
        let request = NSMutableURLRequest(url: NSURL(string: "http://147.46.242.219/addgyro2.php")! as URL)
        request.httpMethod = "POST"
        let postString = "a=\(x)"
        //print("This is the String \(postString)")
        print(postString)
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
    
    override func didDeactivate() {
        super.didDeactivate()
        
        motionManager.stopDeviceMotionUpdates()
    }
}
