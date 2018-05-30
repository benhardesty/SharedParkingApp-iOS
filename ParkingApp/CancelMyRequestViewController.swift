//
//  CancelMyRequestViewController.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import UIKit

class CancelMyRequestViewController: UIViewController {

    // MARK: Outlets
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var addressTextField: UITextView!
    @IBOutlet var typeTextField: UITextField!
    @IBOutlet var fromTextField: UITextField!
    @IBOutlet var toTextField: UITextField!
    @IBOutlet var accessTextField: UITextField!
    @IBOutlet var hoursTextView: UITextView!
    @IBOutlet var renterTextField: UITextField!
    @IBOutlet var vehicleTextField: UITextField!
    @IBOutlet var priceTextField: UITextField!
    
    // MARK: variables
    
    var request:PendingRequest!
    var address:String!
    var from:String!
    var to:String!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var ipAddress:String!
    
    // MARK: View did load
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ipAddress = appDelegate.ipAddress
        
        self.navigationController?.navigationBar.barTintColor = appDelegate.colorPrimaryDark
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        self.scrollView.contentSize.height = 520
        self.title = "My Pending Request"
        
        addressTextField.text = self.request.getSpotAddress()
        typeTextField.text = self.request.getReservationType()
        
        let start = request.getStart()
        let end = request.getEnd()
        
        var fromText = ""
        var toText = ""
        
        switch request.getReservationType() {
        case "Monthly":
            if end == "none" {
                let startText = start.components(separatedBy: "/")
                fromText = "\(startText[1])/\(startText[2])/\(startText[0])"
                toText = "Recurring Monthly"
            } else {
                let startText = start.components(separatedBy: "/")
                let endText = end.components(separatedBy: "/")
                fromText = "\(startText[1])/\(startText[2])/\(startText[0])"
                toText = "\(endText[1])/\(endText[2])/\(endText[0])"
            }
            break
        case "Daily":
            let startText = start.components(separatedBy: "/")
            let endText = end.components(separatedBy: "/")
            fromText = "\(startText[1])/\(startText[2])/\(startText[0])"
            toText = "\(endText[1])/\(endText[2])/\(endText[0])"
            break
        case "Hourly":
            let startText = start.components(separatedBy: "/")
            let endText = end.components(separatedBy: "/")
            
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
        accessTextField.text = self.request.getAccess()
        
        hoursTextView.text = generateHoursStringFromJSON(parseHoursData(self.request.getHours()) as! [String : AnyObject])
        
        let userDetails = parseHoursData(request.getRenterDetails())
        self.renterTextField.text = "\(userDetails["firstName"] as! String) \(userDetails["lastName"] as! String)"
        self.vehicleTextField.text = "\(userDetails["vehicleYear"] as! String) \(userDetails["vehicleColor"] as! String) \(userDetails["vehicleMake"] as! String) \(userDetails["vehicleModel"] as! String)"
        
        priceTextField.text = "\(self.request.getTotalPrice())"
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
    
    // Display alert message
    func displayAlertMessage(_ userMessage: String) {
        let alert = UIAlertController(title: "Alert", message: userMessage, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated:true, completion: nil)
    }
    
    /*
     @Params: JSON data with escaped characters.
     @Returns: JSON data without escaped characters.
    */
    func parseHoursData(_ data:String) -> NSDictionary {
        
        var returnJSON:NSDictionary = ["":""]
        let data2 = data.replacingOccurrences(of: "&quot;", with: "\"", options: NSString.CompareOptions.literal, range: nil)
        let data3:Data = data2.data(using: String.Encoding.utf8)!
        
        do{
            let json = try JSONSerialization.jsonObject(with: data3, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
            returnJSON = json!
        } catch _ as NSError {
        }
        
        return returnJSON
        
    }
    
    /*
     @Params: Availability data in JSON.
     @Returns: Availability data in human readable format.
    */
    func generateHoursStringFromJSON(_ json: [String : AnyObject]) -> String{
        
        var hours:String = ""
        
        if json.count < 15 {
            hours += "M: Not Available" + "\nT: Not Available" + "\nW: Not Available" + "\nTh: Not Available" + "\nF: Not Available" +
                "\nSa: Not Available" + "\nSu: Not Available"
            return hours
        }
        
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
    
    // Cancel the user's pending request
    @IBAction func cancelButtonTapped(_ sender: AnyObject) {
        
        let sessionid = UserDefaults.standard.object(forKey: "sessionid")!
        let myURL = URL(string: "https://" + ipAddress + "")
        let postString = "sessionid=\(sessionid)&requestID=\(self.request.getRequestID())"
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
                    let messageToDisplay:String = parseJSON["message"] as! String
                    
                    DispatchQueue.main.async(execute: {
                        
                        // Display alert message with confirmation
                        let alert = UIAlertController(title: "Alert", message: messageToDisplay, preferredStyle: UIAlertControllerStyle.alert)
                        var okAction: UIAlertAction
                        
                        if(resultValue == "Success") {
                            okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {
                                action in
                                self.dismiss(animated: true, completion: nil)
                            })
                        } else {
                            if messageToDisplay == "Please log in." {
                                self.appDelegate.logoutFunction()
                                return
                            } else {
                                okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
                            }
                        }
                        
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                        
                    })
                    
                }
            } catch _ as NSError {
            }
            
        }
        task.resume()
    }

}
