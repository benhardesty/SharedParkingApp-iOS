//
//  RegisterViewController.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import UIKit

class RegisterViewController: UIViewController {

    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var userEmailTextField: UITextField!
    @IBOutlet var userPasswordTextField: UITextField!
    @IBOutlet var userConfirmPasswordTextField: UITextField!
    @IBOutlet var userFirstNameTextField: UITextField!
    @IBOutlet var userLastNameTextField: UITextField!
    @IBOutlet var makeTextField: UITextField!
    @IBOutlet var modelTextField: UITextField!
    @IBOutlet var colorTextField: UITextField!
    @IBOutlet var yearTextField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var ipAddress:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ipAddress = appDelegate.ipAddress
        scrollView.contentSize.height = 563
        
        // Create a UIToolBar for the 'done' button of the UIPickers
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 0, green: 0, blue: 255, alpha: 1)
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(RegisterViewController.donePicker))
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        userEmailTextField.inputAccessoryView = toolBar
        userPasswordTextField.inputAccessoryView = toolBar
        userConfirmPasswordTextField.inputAccessoryView = toolBar
        userFirstNameTextField.inputAccessoryView = toolBar
        userLastNameTextField.inputAccessoryView = toolBar
        makeTextField.inputAccessoryView = toolBar
        modelTextField.inputAccessoryView = toolBar
        colorTextField.inputAccessoryView = toolBar
        yearTextField.inputAccessoryView = toolBar
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Attempt to register user.
    @IBAction func registerButtonTapped(_ sender: AnyObject) {
        
        let userEmail = userEmailTextField.text
        let userPassword = userPasswordTextField.text
        let userConfirmPassword = userConfirmPasswordTextField.text
        let userFirstName = userFirstNameTextField.text
        let userLastName = userLastNameTextField.text
        let userVehicleMake = makeTextField.text
        let userVehicleModel = modelTextField.text
        let userVehicleColor = colorTextField.text
        let userVehicleYear = yearTextField.text
        
        // Check for empty fields.
        if(userEmail!.isEmpty || userPassword!.isEmpty || userConfirmPassword!.isEmpty || userFirstName!.isEmpty || userLastName!.isEmpty) {
            displayAlertMessage("Missing required field.")
            return
        }
        
        // Check that the email entered is valid.
        if !isValidEmail(email: userEmail!) {
            displayAlertMessage("Not a valid email")
            return
        }
        
        // Check that password and confirm password match.
        if(userPassword != userConfirmPassword) {
            displayAlertMessage("Passwords do not match")
            return
        }
        
        self.signUpButton.backgroundColor = UIColor.lightGray
        
        let myURL = URL(string: "https://" + ipAddress + "")
        let postString = "email=\(userEmail!)&password=\(userPassword!)&firstName=\(userFirstName!)&lastName=\(userLastName!)&vehicleMake=\(userVehicleMake!)&vehicleModel=\(userVehicleModel!)&vehicleColor=\(userVehicleColor!)&vehicleYear=\(userVehicleYear!)"
        let request = NSMutableURLRequest(url: myURL!)
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if data == nil {
                DispatchQueue.main.async(execute: {
                    self.displayAlertMessage("Could not reach server. Please try again")
                    self.signUpButton.backgroundColor = self.appDelegate.colorPrimaryDark
                })
                return
            }
            
            do{
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    let resultValue = parseJSON["status"] as? String
                    
                    var isUserRegistered:Bool = false;
                    if(resultValue == "Success") {
                        isUserRegistered = true
                    }
                    
                    let messageToDisplay:String = parseJSON["message"] as! String
                    
                    DispatchQueue.main.async(execute: {
                        
                        // Display alert message with confirmation
                        let alert = UIAlertController(title: "Alert", message: messageToDisplay, preferredStyle: UIAlertControllerStyle.alert)
                        var okAction: UIAlertAction
                        
                        if(isUserRegistered) {
                            okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {
                                action in
                                self.dismiss(animated: true, completion: nil)
                            })
                        } else {
                            okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
                        }
                        
                        self.signUpButton.backgroundColor = self.appDelegate.colorPrimaryDark
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                    })
                }
            } catch _ as NSError {
                DispatchQueue.main.async(execute: {
                    self.signUpButton.backgroundColor = self.appDelegate.colorPrimaryDark
                })
            }
        }
        task.resume()
    }
    
    // Display alert message
    func displayAlertMessage(_ userMessage: String) {
        let alert = UIAlertController(title: "Alert", message: userMessage, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated:true, completion: nil)
    }
    
    // Release keyboard.
    func donePicker(){
        userEmailTextField.resignFirstResponder()
        userPasswordTextField.resignFirstResponder()
        userConfirmPasswordTextField.resignFirstResponder()
        userFirstNameTextField.resignFirstResponder()
        userLastNameTextField.resignFirstResponder()
        makeTextField.resignFirstResponder()
        modelTextField.resignFirstResponder()
        colorTextField.resignFirstResponder()
        yearTextField.resignFirstResponder()
    }
    
    /*
     @Params: Email string.
     @Returns: True or false based on whether or not it is a valid email.
     */
    func isValidEmail(email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }
    
    // Bring user back to login screen.
    @IBAction func alreadyHaveAccountButtonTapped(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}
