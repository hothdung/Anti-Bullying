//
//  InterfaceController.swift
//  AudioTest WatchKit Extension
//
//  Created by 신유정 on 23/05/2019.
//  Copyright © 2019 Dung Ho. All rights reserved.
//

import WatchKit
import Foundation
import AVFoundation

class InterfaceController: WKInterfaceController, AVAudioRecorderDelegate{
    @IBOutlet weak var btn: WKInterfaceButton!
    var recordingSession : AVAudioSession!
    var audioRecorder : AVAudioRecorder!
    var settings = [String : Any]()
    var player: AVAudioPlayer?
    var filename: String?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
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
        
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
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
        print("Marker1: \(filePath)")
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
            //audioRecorder = nil
            print("Somthing Wrong.")
        }
    }
    
    
    @IBAction func recordAudio() {
        
    
        if audioRecorder == nil {
            print("Pressed")
            self.btn.setTitle("Stop")
            self.btn.setBackgroundColor(UIColor(red: 119.0/255.0, green: 119.0/255.0, blue: 119.0/255.0, alpha: 1.0))
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
            
            self.btn.setTitle("Record")
            print("Pressed2")
            self.btn.setBackgroundColor(UIColor(red: 221.0/255.0, green: 27.0/255.0, blue: 50.0/255.0, alpha: 1.0))
            self.finishRecording(success: true)
            
        }
       
        
    
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    @IBAction func startPlayAudio() {
        let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let url = URL(fileURLWithPath: path)
        let pathPart = url.appendingPathComponent("sound.wav")
        let filePath = pathPart.path
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath){
            print("File exists!")
            do {
                player = try AVAudioPlayer(contentsOf: audioRecorder.url)
                player?.play()
            } catch {
                
                print("File cannot be played!")
            }
        }else{
            print("File does not exist!")
        }
    }
    
}


