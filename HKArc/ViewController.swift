//
//  ViewController.swift
//  HKArc
//
//  Created by Eric Tan on 7/31/15.
//  Copyright (c) 2015 Harman International. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var volumeLabel: UILabel!
    @IBOutlet weak var stopBtn: UIButton!
    @IBOutlet weak var resultView: UITextView!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var successLabel: UILabel!
    
    let config = ACRCloudConfig()
    var client: ACRCloudRecognition!
    var startTime: NSTimeInterval!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initACRRecorder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func stopPressed(sender: UIButton) {
        client.stopRecordRec()
    }
    
    /* Initializes the ACR recorder and starts recording */
    func initACRRecorder() {
        
        config.accessKey = "754a02bc6223fc2403f260aadbe32ae8"
        config.accessSecret = "Q7TD0rS32ZRViJf1UR8JKBb4ZctoIwkx5ug148Rr"
        config.host = "ap-southeast-1.api.acrcloud.com"
        config.recMode = rec_mode_remote
        config.audioType = "recording"
        config.requestTimeout = 7
        
        config.stateBlock = {state in
            self.handleState(state)
        }
        
        config.volumeBlock = {volume in
            self.handleVolume(volume)
        }
        
        config.resultBlock = {result, resType in
            self.handleResult(result, resType: resType)
        }
        
        client = ACRCloudRecognition(config: config)
        
        // Init text in labels to be empty.
        resultView.text = ""
        successLabel.text = ""
        
        // Start recorder
        client.startRecordRec()

    }
    
    /* Callback method for handling the event when the recorder is done looping. */
    func handleResult(result: String, resType: ACRCloudResultType) {
    
        println("\(result)");
        
        dispatch_async(dispatch_get_main_queue(), {
            self.resultView.text = result
            
            // Initialize JSON parsing
            if let dataFromString = result.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
                let json = JSON(data: dataFromString)
                
                // Check if successful shower sound recognition 
                if json["status"]["msg"] == "No result" {
                    println("Failed to find shower noise\n")
                }
                else if json["status"]["msg"] == "Success" {
                    if json["metadata"]["custom_files"][0]["audio_id"] == "shower_running" {
                        // Set success label!
                        self.successLabel.text = "I hear the shower!"
                        
                        // Stop recording
                        self.client.stopRecordRec()
                        
                        // Send event to Harman IoT Cloud to start timer for shower (<5 minutes)
                        // Insert code here...
                    }
                }
            }
            
            
        })

    }
    
    func getCurrentTime() -> String {
        let date = NSDate()
        let formatter = NSDateFormatter()
        formatter.timeStyle = NSDateFormatterStyle.ShortStyle
        return formatter.stringFromDate(date);
    }
    
    /* Callback method for handling the change in volume */
    func handleVolume(volume: Float) {
        dispatch_async(dispatch_get_main_queue(), {
            self.volumeLabel.text = String("Volume \(volume)")
            });
    }
    
    /* Callback for handling the change in state */
    func handleState(state: String) {
        dispatch_async(dispatch_get_main_queue(), {
            self.stateLabel.text = String("State: \(state)")
        });
    }

}

