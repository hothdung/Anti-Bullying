//
//  AudioInterfaceController.swift
//  AudioTestEx WatchKit Extension
//
//

import WatchKit
import Foundation
import AVFoundation
import Alamofire


class AudioInterfaceController: WKInterfaceController {
    
    var outputURL: URL!
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
    }
    
    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }
    

    @IBAction func playFile() {
     
        presentMediaPlayerController(
            with: outputURL,
            options: nil,
            completion: {_,_,_ in })
        //print(outputURL)
    }
    
    
    @IBAction func recordFile() {
        outputURL = MemoFileNameHelper.newOutputURL()
        
        let preset = WKAudioRecorderPreset.narrowBandSpeech
        
        let options: [String:Any] = [WKAudioRecorderControllerOptionsMaximumDurationKey: 10]
        presentAudioRecorderController(withOutputURL: outputURL, preset: preset, options: options,  completion: { saved, error in
            
            if let err = error {
                print(err.localizedDescription)
            }
        })
    }
    
    
    @IBAction func sendFile() {
   let fileName = outputURL.lastPathComponent
    guard let audioFile: Data = try? Data (contentsOf: outputURL) else {return}
    AF.upload(multipartFormData: { (multipartFormData) in
    multipartFormData.append(audioFile, withName: "audio", fileName: fileName, mimeType: "audio/m4a")
    }, to: "http://147.46.242.219/addsound.php").responseJSON { (response) in
    debugPrint(response)
        }
    }

    
}

class MemoFileNameHelper {
    
    /// A date formatter to format Date to a string suitable to be used as a file name.
    static let dateFormatterForFileName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMddHHmmssZZZ"
        return formatter
    }()
    
    /// Returns a new unique output URL based on user's document directory for to-be-saved voice memo.
    static func newOutputURL() -> URL {
        let dateFormatter = MemoFileNameHelper.dateFormatterForFileName
        let date = Date()
        let filename = dateFormatter.string(from: date)
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let output = documentsDirectoryURL.appendingPathComponent("\(filename).m4a")
        return output
    }
}

