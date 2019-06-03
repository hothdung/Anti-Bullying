//
//  AppDelegate.swift
//  BullyingDetection
//
//  Created by 신유정 on 28/04/2019.
//  Copyright © 2019 Dung Ho. All rights reserved.
//

import UIKit
import CoreLocation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let locationManager = CLLocationManager()
    var bgIdentifier: UIBackgroundTaskIdentifier?
    var replyHandler:([NSObject : AnyObject]?)->Void = {arg in}

    func application(application: UIApplication,
                     handleWatchKitExtensionRequest userInfo:
        [NSObject : AnyObject]?,
                     reply: (([NSObject : AnyObject]?) -> Void)!) {
        
        replyHandler = reply
        
        bgIdentifier = application.beginBackgroundTask(
            withName: "MyTask", expirationHandler: { () -> Void in
                print("Time expired")
        })
        locationManager.delegate = self as! CLLocationManagerDelegate
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        
        locationManager.stopUpdatingLocation()
        
        let currentLocation = locations[locations.count - 1]
            as? CLLocation
        
        var replyValues = Dictionary<String, AnyObject>()
        
        replyValues["latitude"] = currentLocation?.coordinate.latitude as AnyObject?
        replyValues["longitude"] = currentLocation?.coordinate.longitude as AnyObject?
        
        
        UIApplication.shared.endBackgroundTask(bgIdentifier!)
        
        replyHandler(replyValues as [NSObject : AnyObject])
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

