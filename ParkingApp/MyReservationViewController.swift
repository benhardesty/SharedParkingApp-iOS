//
//  MyReservationViewController.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import UIKit

class MyReservationViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    // MARK: Outlets
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var addressTextField: UITextView!
    @IBOutlet var typeTextField: UITextField!
    @IBOutlet var fromTextField: UITextField!
    @IBOutlet var toTextField: UITextField!
    @IBOutlet var accessTextField: UITextField!
    @IBOutlet var hoursTextField: UITextView!
    @IBOutlet var renterTextField: UITextField!
    @IBOutlet var vehicleTextField: UITextField!
    @IBOutlet var reasonTextField: UITextField!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var reasonLabel: UILabel!
    @IBOutlet var cancelButton: UIButton!
    
    // MARK: Global Variables
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var ipAddress:String!
    var reservation:Reservation!
    var spot:ParkingSpot!
    var hours:String!
    var previousViewController:String = ""
    var phpFile:String!
    var reasons:[String] = ["No longer need the spot", "Spot inaccurately represented", "Spot is fraudulent", "Spot Owner", "Other"]
    var reasonPicker = UIPickerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ipAddress = appDelegate.ipAddress
        self.navigationController?.navigationBar.barTintColor = appDelegate.colorPrimaryDark
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        self.title = "My Reservation"
        self.scrollView.contentSize.height = 569
        
        // This view is used by two different presenting segues.
        if(previousViewController == "MySpotViewController") {
            phpFile = "https://" + ipAddress + ""
            reasons = ["Spot no longer available", "Renter inaccurately represented themselves", "Fraud", "Renter", "Other"]
            self.title = "Reservation"
        } else {
            phpFile = "https://" + ipAddress + ""
        }
        
        self.addressTextField.text = reservation.getSpotAddress()
        self.typeTextField.text = reservation.getReservationType()
        var fromText = ""
        var toText = ""
        
        switch reservation.getReservationType() {
        case "Monthly":
            if self.reservation.getEnd() == "none" {
                let startText = self.reservation.getStart().components(separatedBy: "/")
                fromText = "\(startText[1])/\(startText[2])/\(startText[0])"
                toText = "Recurring Monthly"
            } else {
                let startText = self.reservation.getStart().components(separatedBy: "/")
                let endText = self.reservation.getEnd().components(separatedBy: "/")
                fromText = "\(startText[1])/\(startText[2])/\(startText[0])"
                toText = "\(endText[1])/\(endText[2])/\(endText[0])"
            }
            break
        case "Daily":
            let startText = self.reservation.getStart().components(separatedBy: "/")
            let endText = self.reservation.getEnd().components(separatedBy: "/")
            fromText = "\(startText[1])/\(startText[2])/\(startText[0])"
            toText = "\(endText[1])/\(endText[2])/\(endText[0])"
            break
        case "Hourly":
            let startText = self.reservation.getStart().components(separatedBy: "/")
            let endText = self.reservation.getEnd().components(separatedBy: "/")
            let startTime = convert24to12(time: startText[3] + ":" + startText[4])
            let endTime = convert24to12(time: endText[3] + ":" + endText[4])
            fromText = "\(startText[1])/\(startText[2])/\(startText[0]): \(startTime)"
            toText = "\(startText[1])/\(startText[2])/\(startText[0]): \(endTime)"
            break
        default:
            break
        }
        
        fromTextField.text = fromText
        toTextField.text = toText
        
        self.accessTextField.text = reservation.getAccess()
        self.hoursTextField.text = generateHoursStringFromJSON(parseHoursData(reservation.getHours()) as! [String : AnyObject])
        self.renterTextField.text = reservation.getRenterName().replacingOccurrences(of: "&quot;", with: "\"", options: NSString.CompareOptions.literal, range: nil) as String
        self.vehicleTextField.text = reservation.getRenterVehicle().replacingOccurrences(of: "&quot;", with: "\"", options: NSString.CompareOptions.literal, range: nil)
        
        // Create a UIToolBar for the 'done' button of the UIPickers
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 0, green: 0, blue: 255, alpha: 1)
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(MyReservationViewController.donePicker))
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        // Initialize spotPicker resources
        reasonPicker.delegate = self
        reasonPicker.dataSource = self
        reasonTextField.inputView = reasonPicker
        reasonTextField.inputAccessoryView = toolBar
    }
    
    /*
     @Params: Takes in a string of the time in 24hr format 'HH:MM'
     @Returns: String of the time in 12hr format 'HH:MM XX' where XX is 'AM' or 'PM'
     */
    func convert24to12(time: String) -> String {
        if Int(time.components(separatedBy: ":")[0])! < 13 {
            if time.components(separatedBy: ":")[0] == "00" {
                return "01:" + time.components(separatedBy: ":")[1] + " AM"
            }
            return time + " AM"
        } else {
            let hour = Int(time.components(separatedBy: ":")[0])! - 12
            let minutes = time.components(separatedBy: ":")[1]
            return String(hour) + ":" + minutes + " PM"
        }
    }
    
    // Clean escaped characters from JSON.
    func parseHoursData(_ data:String) -> NSDictionary {
        
        var returnJSON:NSDictionary!
        let data2 = data.replacingOccurrences(of: "&quot;", with: "\"", options: NSString.CompareOptions.literal, range: nil)
        let data3:Data = data2.data(using: String.Encoding.utf8)!
        
        do{
            let json = try JSONSerialization.jsonObject(with: data3, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
            returnJSON = json!
        } catch _ as NSError {
        }
        return returnJSON
    }
    
    /**
     @Params: Availability hours in JSON.
     @Returns: Availability hours in human-readable string.
     */
    func generateHoursStringFromJSON(_ json: [String : AnyObject]) -> String{
        
        var hours:String = ""
        
        if(json["mondaySwitch"] as! String == "true") {
            hours = hours + "M: \(json["mondayFrom"]!) - \(json["mondayTo"]!)"
        } else {
            hours = hours + "M: Not Available"
        }
        if(json["tuesdaySwitch"] as! String == "true") {
            hours = hours + "\nT: \(json["tuesdayFrom"]!) - \(json["tuesdayTo"]!)"
        } else {
            hours = hours + "\nT: Not Available"
        }
        if(json["wednesdaySwitch"] as! String == "true") {
            hours = hours + "\nW: \(json["wednesdayFrom"]!) - \(json["wednesdayTo"]!)"
        } else {
            hours = hours + "\nW: Not Available"
        }
        if(json["thursdaySwitch"] as! String == "true") {
            hours = hours + "\nTh: \(json["thursdayFrom"]!) - \(json["thursdayTo"]!)"
        } else {
            hours = hours + "\nTh: Not Available"
        }
        if(json["fridaySwitch"] as! String == "true") {
            hours = hours + "\nF: \(json["fridayFrom"]!) - \(json["fridayTo"]!)"
        } else {
            hours = hours + "\nF: Not Available"
        }
        if(json["saturdaySwitch"] as! String == "true") {
            hours = hours + "\nSa: \(json["saturdayFrom"]!) - \(json["saturdayTo"]!)"
        } else {
            hours = hours + "\nSa: Not Available"
        }
        if(json["sundaySwitch"] as! String == "true") {
            hours = hours + "\nSu: \(json["sundayFrom"]!) - \(json["sundayTo"]!)"
        } else {
            hours = hours + "\nSu: Not Available"
        }
        return hours
    }
    
    // returns the number of 'columns' to display.
    @available(iOS 2.0, *)
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // Returns the # of rows in each component.
    @available(iOS 2.0, *)
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == reasonPicker {
            return reasons.count
        } else {
            return 0
        }
    }
    
    // Set the Spot_Type_Text_Field text to the selected row when a row is selected.
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == reasonPicker {
            reasonTextField.text = reasons[row]
        }
    }
    
    // Title for row.
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == reasonPicker {
            return reasons[row]
        } else {
            return ""
        }
    }
    
    // Release keyboard.
    func donePicker(){
        reasonTextField.resignFirstResponder()
    }
    
    // Display alert message
    func displayAlertMessage(_ userMessage: String) {
        let alert = UIAlertController(title: "Alert", message: userMessage, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
        
        alert.addAction(okAction)
        
        self.present(alert, animated:true, completion: nil)
    }
    
    // Present button to cancel reservation.
    @IBAction func firstCancelButtonClicked(_ sender: AnyObject) {
        self.reasonLabel.isHidden = false
        self.reasonTextField.isHidden = false
        self.cancelButton.isHidden = false
    }
    
    // Attempt to cancel user's reservation.
    @IBAction func cancelButtonTapped(_ sender: AnyObject) {
        
        let reason = self.reasonTextField.text!
        let sessionid = UserDefaults.standard.object(forKey: "sessionid")!
        
        let myURL = URL(string: phpFile)
        let postString = "sessionid=\(sessionid)&reservationID=\(self.reservation.getReservationID())&reason=\(reason)"
        let request = NSMutableURLRequest(url: myURL!)
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if (data == nil) {
                DispatchQueue.main.async(execute: {
                    self.displayAlertMessage("Could not reach server. Please try again.")
                })
                return
            }
            
            do{
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    
                    let resultValue = parseJSON["status"] as? String
                    
                    DispatchQueue.main.async(execute: {
                        
                        var alert:UIAlertController
                        var okAction: UIAlertAction
                        
                        if(resultValue == "Success") {
                            
                            let messageToDisplay:String = parseJSON["message"] as! String
                            
                            // Display alert message with confirmation
                            alert = UIAlertController(title: "Alert", message: messageToDisplay, preferredStyle: UIAlertControllerStyle.alert)
                            okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {
                                action in
                                self.dismiss(animated: true, completion: nil)
                            })
                            alert.addAction(okAction)
                            self.present(alert, animated: true, completion: nil)
                            
                        } else {
                            let messageToDisplay:String = parseJSON["message"] as! String
                            
                            if messageToDisplay == "Please log in." {
                                self.appDelegate.logoutFunction()
                            } else {
                                // Display alert message with confirmation
                                alert = UIAlertController(title: "Alert", message: messageToDisplay, preferredStyle: UIAlertControllerStyle.alert)
                                okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
                                alert.addAction(okAction)
                                self.present(alert, animated: true, completion: nil)
                            }
                        }
                    })
                }
            } catch _ as NSError {
            }
        }
        task.resume()
    }
    
    @IBAction func backButtonClicked(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
}
