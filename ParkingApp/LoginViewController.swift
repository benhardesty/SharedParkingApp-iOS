//
//  LoginViewController.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import UIKit
import MMDrawerController

class LoginViewController: UIViewController {

    @IBOutlet var userEmailTextField: UITextField!
    @IBOutlet var userPasswordTextField: UITextField!
    
    @IBOutlet weak var forgotPasswordStackView: UIStackView!
    @IBOutlet weak var forgotEmailSubmitButton: UIButton!
    @IBOutlet weak var forgotEmailTextField: UITextField!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var ipAddress:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ipAddress = appDelegate.ipAddress
        
        // Create a UIToolBar for the 'done' button of the UIPickers
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 0, green: 0, blue: 255, alpha: 1)
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(LoginViewController.donePicker))
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        userEmailTextField.inputAccessoryView = toolBar
        userPasswordTextField.inputAccessoryView = toolBar
        
        self.forgotEmailTextField.inputAccessoryView = toolBar
        self.forgotPasswordStackView.isHidden = true
        self.forgotEmailSubmitButton.isHidden = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Release keyboard.
    func donePicker(){
        userEmailTextField.resignFirstResponder()
        userPasswordTextField.resignFirstResponder()
        forgotEmailTextField.resignFirstResponder()
    }
    
    @IBAction func unwindCancelToLoginViewController(_ unwindSegue: UIStoryboardSegue){
        
    }
    
    // Display alert message
    func displayAlertMessage(_ userMessage: String) {
        let alert = UIAlertController(title: "Alert", message: userMessage, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
        
        alert.addAction(okAction)
        
        self.present(alert, animated:true, completion: nil)
    }
    
    // Present a field for the user to enter their email if they forgot their password.
    @IBAction func initialForgotPasswordButtonClicked(_ sender: Any) {
        self.forgotPasswordStackView.isHidden = false
        self.forgotEmailSubmitButton.isHidden = false
    }
    
    // Send user an email to reset their password.
    @IBAction func forgotPasswordButtonClicked(_ sender: Any) {
        if self.forgotEmailTextField.text == "" {
            displayAlertMessage("Please enter an email address.")
            return
        }
        
        self.forgotEmailSubmitButton.backgroundColor = UIColor.lightGray
        
        let postString = "email=\(self.forgotEmailTextField.text!)"
        let myURL = URL(string: "https://" + self.ipAddress + "")
        let request = NSMutableURLRequest(url: myURL!)
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if(data == nil) {
                
                DispatchQueue.main.async(execute: {
                    self.displayAlertMessage("Could not reach server. Please try again.")
                    self.forgotEmailSubmitButton.backgroundColor = self.appDelegate.colorPrimary
                })
                return
            }
            
            do{
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    
                    let message = parseJSON["message"] as? String
                    
                    DispatchQueue.main.async(execute: {
                        self.displayAlertMessage(message!)
                        self.forgotEmailSubmitButton.backgroundColor = self.appDelegate.colorPrimary
                    })
                }
            } catch _ as NSError {
                DispatchQueue.main.async(execute: {
                    self.displayAlertMessage("There was an error. Please try again.")
                    self.forgotEmailSubmitButton.backgroundColor = self.appDelegate.colorPrimary
                })
            }
        }.resume()
    }
    
    // Sign user in.
    @IBAction func loginSignupButtonTapped(_ sender: AnyObject) {
        
        let userEmail = userEmailTextField.text
        let userPassword = userPasswordTextField.text
        let application = "ios"
        
        if(userEmail!.isEmpty || userPassword!.isEmpty) {
            
            let alertMessage:String = "Please enter email and password";
            
            // Display alert message with confirmation
            let alert = UIAlertController(title: "Alert", message: alertMessage, preferredStyle: UIAlertControllerStyle.alert)
            
            let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
            
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
            
            return
        }
        
        let myURL = URL(string: "https://" + ipAddress + "")
        let postString = "email=\(userEmail!)&password=\(userPassword!)&application=\(application)"
        let request = NSMutableURLRequest(url: myURL!)
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if data == nil {
                DispatchQueue.main.async(execute: {
                    self.displayAlertMessage("Could not reach server. Please try again")
                })
                
                return
            }
            
            do{
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    let resultValue = parseJSON["status"] as? String
                    
                    if(resultValue == "Success") {
                        
                        // Login is successful
                        
                        let sessionid = parseJSON["sessionID"]!
                        
                        UserDefaults.standard.set(sessionid, forKey: "sessionid")
                        UserDefaults.standard.set(true, forKey: "isUserLoggedIn")
                        UserDefaults.standard.synchronize()
                        
                        DispatchQueue.main.async(execute: {
                            self.userIsLoggedIn()
                        })
                        
                    } else {
                        DispatchQueue.main.async(execute: {
                            
                            let messageToDisplay:String = parseJSON["message"] as! String
                            let alert = UIAlertController(title: "Alert", message: messageToDisplay, preferredStyle: UIAlertControllerStyle.alert)
                            let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
                            alert.addAction(okAction)
                            self.present(alert, animated: true, completion: nil)
                        })
                    }
                }
            } catch _ as NSError {
            }
        }
        task.resume()
    }
    
    // If login is successful, send them to the Map view.
    func userIsLoggedIn() {
        
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        
        let mainStoryBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let centerViewController = mainStoryBoard.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        let leftViewController = mainStoryBoard.instantiateViewController(withIdentifier: "LeftSideViewController") as! LeftSideViewController
        let leftSideNav = UINavigationController(rootViewController: leftViewController)
        let centerNav = UINavigationController(rootViewController: centerViewController)
        let centerContainer: MMDrawerController = MMDrawerController(center: centerNav, leftDrawerViewController: leftSideNav)
        
        centerContainer.openDrawerGestureModeMask = MMOpenDrawerGestureMode.panningCenterView
        centerContainer.closeDrawerGestureModeMask = MMCloseDrawerGestureMode.panningCenterView
        
        appDelegate.centerContainer = centerContainer
        appDelegate.window!.rootViewController = appDelegate.centerContainer
        appDelegate.window!.makeKeyAndVisible()
    }

}
