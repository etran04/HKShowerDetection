//
//  LoginViewController.swift
//  HKShowerDetection
//
//  Created by Eric Tan on 8/4/15.
//  Copyright (c) 2015 Harman International. All rights reserved.
//

import Foundation
import UIKit
import Parse

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var registerBtn: UIButton!
    @IBOutlet weak var loginBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Skips login screen if user already logged in previously
        var currentUser = PFUser.currentUser()
        if currentUser != nil {
            self.performSegueWithIdentifier("loginSegue", sender: self)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func loginPressed(sender: UIButton) {
        self.login()
    }
    
    @IBAction func registerPressed(sender: UIButton) {
        self.signUserUp()
    }
    
    /* Helper method for logging in */
    func login() {
        
        if (usernameField.text == "" || passwordField.text == "") {
            println("No input!")
        }
        else {
        
            PFUser.logInWithUsernameInBackground(usernameField.text, password: passwordField.text) { (user: PFUser?, error: NSError?) -> Void in
                if user != nil {
                    let installation = PFInstallation.currentInstallation()
                    installation["user"] = user
                    self.performSegueWithIdentifier("loginSegue", sender: self)
                    installation.saveInBackgroundWithBlock({ (success, error) -> Void in

                    })
                } else {
                    let errorString = error!.userInfo?["error"] as? String
                    let alert = UIAlertController(title: "Error", message: errorString, preferredStyle: UIAlertControllerStyle.Alert)
                    let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
                    alert.addAction(ok)
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
            
        }
    }
    
    /* Helper method for signing user up */
    func signUserUp() {
        var user = PFUser()
        user.username = usernameField.text
        user.password = passwordField.text
        
        user.signUpInBackgroundWithBlock { (succeded: Bool, error: NSError?) -> Void in
            if succeded {
                let installation = PFInstallation.currentInstallation()
                installation["user"] = user
                self.performSegueWithIdentifier("loginSegue", sender: self)
                installation.saveInBackgroundWithBlock({ (success, error) -> Void in
                    
                })
            }
            else {
                if let error = error {
                    let errorString = error.userInfo?["error"] as? String
                    let alert = UIAlertController(title: "Username Taken", message: errorString, preferredStyle: UIAlertControllerStyle.Alert)
                    let ok = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
                    alert.addAction(ok)
                    self.presentViewController(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
}