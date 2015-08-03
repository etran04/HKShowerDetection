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
        
        config.accessKey = "133d1cb76704e1af96e93463ffb10c55"
        config.accessSecret = "x6w2pFiCnLB9H0Lt8SDfLTvJmiR3vdhuUz9NjIGr"
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
                    self.successLabel.text = "Did you start the shower?"
                }
                else if json["status"]["msg"] == "Success" {
                    if json["metadata"]["custom_files"][0]["audio_id"] == "shower_running" {
                        // Set success label!
                        self.successLabel.text = "I heard the shower!"
                        
                        // Stop recording
                        self.client.stopRecordRec()
                        
                        // Send event to Harman IoT Cloud to start timer for shower (<5 minutes)
                        // Insert code here...
                    }
                }
            }
            
            
        })

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

