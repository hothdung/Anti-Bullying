//
//  InterfaceController.swift
//  BullyingDetection WatchKit Extension
//
//  Created by Dung Ho on 28/04/2019.
//  Copyright © 2019 Dung Ho. All rights reserved.
//

import WatchKit
import Foundation
import CoreLocation


// retrieve components of full date: date, day, time
extension Date{
    func getDate(date: String)->String?{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = date
        return dateFormatter.string(from: self)
        
    }
}


class InterfaceController: WKInterfaceController {
    
    // preparing JSON
    struct AddBullySignals: Codable {
        let date: String
        let day: String
        let time: String
    }
    

    @IBOutlet weak var testLabel: WKInterfaceLabel!
    @IBOutlet weak var furtherSigLabels: WKInterfaceLabel!
    var locationManager: CLLocationManager = CLLocationManager()
    var mapLocation: CLLocationCoordinate2D?
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        locationManager = CLLocationManager()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        print("locations = \(locValue.latitude) \(locValue.longitude)")
    }
    
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        
        print(error.description)
    }
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    
    func showLabel(){
        //furtherSigLabels.setHidden(false)
       
        //furtherSigLabels.setText((Date().getDate(date:"yyyy/MMMM/dd")!)+"\n"+(Date().getDate(date:"EEEE")!)+"\n"+(Date().getDate(date:"HH:mm a")!))
        
        // build JSON
        let time_Component = AddBullySignals(date:Date().getDate(date:"yyyy/MMMM/dd")!, day:Date().getDate(date:"EEEE")!, time:Date().getDate(date:"HH:mm a")!)
        
        guard let jsonData = try? JSONEncoder().encode(time_Component) else{
            return
        }
        // test
        let jsonString = String(data: jsonData, encoding: .utf8)
        furtherSigLabels.setText(jsonString)
       //print(jsonString)
       
        // configuration of URL request
        let url = URL(string: "http://147.46.242.219/add.php")!
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
        showLabel()
    }

    
}
