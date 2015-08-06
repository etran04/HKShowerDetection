//
//  ViewController.swift
//  HKArc
//
//  Created by Eric Tan on 7/31/15.
//  Copyright (c) 2015 Harman International. All rights reserved.
//

import UIKit
import Parse
import Foundation
import CoreFoundation

class ShowerSensorViewController: UIViewController {

    @IBOutlet weak var restartBtn: UIButton!
    @IBOutlet weak var logoutBtn: UIButton!
    @IBOutlet weak var volumeLabel: UILabel!
    @IBOutlet weak var stopBtn: UIButton!
    @IBOutlet weak var resultView: UITextView!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var successLabel: UILabel!
    
    let config = ACRCloudConfig()
    var client: ACRCloudRecognition!
    var showerStarted: Bool!
    var timeToAlert: Int!
    var timer: NSTimer!
    var startTime: NSTimeInterval!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showerStarted = false
        initACRRecorder()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    /* Callback for when logout button is pressed */
    @IBAction func logoutPressed(sender: UIButton) {
        PFUser.logOut()
    }
    
    /* Callback for when restart button is pressed */
    @IBAction func restartPressed(sender: UIButton) {
        client.startRecordRec()
    }
    
    /* Callback for when stop button is pressed */
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
    
        if !showerStarted {
            println("\(result)")
        }
        
        dispatch_async(dispatch_get_main_queue(), {
            self.resultView.text = result
            self.parseJSON(result, showerStartedFlag: self.showerStarted)
        })
    }
    
    /* Helper method for going through the JSON and seeing if it recognize shower sound or not. */
    func parseJSON (result: String, showerStartedFlag: Bool) {
        
        // Initialize JSON parsing
        if let dataFromString = result.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            let json = JSON(data: dataFromString)
        
            if json["status"]["msg"] == "No result" {
                
                if !showerStartedFlag {
                    // Shower still hasn't started
                    successLabel.text = "Did you start the shower?"
                }
                else {
                    // Calculated how long shower occured for
                    var elapseTime = CACurrentMediaTime() - startTime
                    var elapseInt = Int(elapseTime)
                    println("You showered for \(elapseInt) seconds total.")
                    
                    // Shower stopped labeled
                    successLabel.text = "You showered for \(elapseInt) seconds!"
                    
                    // Stop recording
                    client.stopRecordRec()
                    
                    // If shower was less than configured time, then stop the timer from firing
                    if elapseInt < timeToAlert {
                        println("Stopped timer from firing!")
                        timer.invalidate()
                    }
                }
            }
            else if json["status"]["msg"] == "Success" {
                hearShower(json)
            }
        }
    }
    
    /* Helper function for what to do after app recoginizes shower sound for the first time */
    func hearShower (json: JSON) {
        if json["metadata"]["custom_files"][0]["audio_id"] == "shower_running" {
            
            // Set success label!
            successLabel.text = "I hear you're showering!"
            
            // Check if first time hear shower or not
            if (!showerStarted) {
                prepTimer()
            }
            else {
                println("Currently in the shower... ")
            }
        }
    }

    /* Helper methodfor querying for the user to get shower config data, and starting the timer */
    func prepTimer() {
        // Query for user, and then his/her shower configuration
        var username = PFUser.currentUser()?.username
        var userQuery = PFUser.query()
        userQuery!.whereKey("username", equalTo: username!)
        userQuery!.getFirstObjectInBackgroundWithBlock {
            (user: PFObject?, error: NSError?) -> Void in
            if error == nil && user != nil {
                // Found the user
                let showerConfigID = (user!["showerConfig"] as! PFObject).objectId
                var showerQuery = PFQuery(className: "ShowerConfig")
                showerQuery.getObjectInBackgroundWithId(showerConfigID!) {
                    (config: PFObject?, error: NSError?) -> Void in
                    if error == nil && config != nil {
                        var timeTillAlert: AnyObject? = config?.objectForKey("timeTillAlert")
                        self.createTimer(timeTillAlert as! Int)
                    }
                }
            }
        }
    }

    /* Helper function for creating and starting timer in the closure */
    func createTimer(secondsTillAlert: Int) {
            showerStarted = true
            startTime = CACurrentMediaTime()
            timeToAlert = secondsTillAlert
            timer = NSTimer.scheduledTimerWithTimeInterval(NSTimeInterval(secondsTillAlert), target: self, selector: "triggerEventInCloud", userInfo: nil, repeats: false)
    }
    
    /* Called when timer has hit user shower config time
     * Triggers event in Parse Cloud to send push notifcation to HKRules application
     */
    func triggerEventInCloud() {
        
        var username = PFUser.currentUser()?.username;
        
        // Send event to Harman IoT Cloud to send a push notification to HKRules
        PFCloud.callFunctionInBackground("showerStarted", withParameters: ["username":username!]) {
            (response: AnyObject?, error: NSError?) -> Void in
            if error != nil {
                println("Error with triggering event.")
            } else {
                println("Triggered event in the cloud!")
                println("Expecting push notification on HKRules app...")
            }
        }
        
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

