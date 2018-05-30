//
//  HoursViewController.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import UIKit

class HoursViewController: UIViewController {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var monthlyHoursTextView: UITextView!
    @IBOutlet var dailyHoursTextView: UITextView!
    @IBOutlet var hourlyHoursTextView: UITextView!
    
    // Hours variables are set during segue from previous view.
    var monthlyHours:String = ""
    var dailyHours:String = ""
    var hourlyHours:String = ""
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = appDelegate.colorPrimaryDark
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        
        self.title = "Hours"
        
        self.scrollView.contentSize.height = 591
        
        let monthlyJSON = self.parseHoursData(monthlyHours)
        let dailyJSON = self.parseHoursData(dailyHours)
        let hourlyJSON = self.parseHoursData(hourlyHours)
        
        self.monthlyHours = self.generateHoursStringFromJSON(monthlyJSON as! [String : AnyObject])
        self.dailyHours = self.generateHoursStringFromJSON(dailyJSON as! [String : AnyObject])
        self.hourlyHours = self.generateHoursStringFromJSON(hourlyJSON as! [String : AnyObject])
        
        self.monthlyHoursTextView.text = self.monthlyHours
        self.dailyHoursTextView.text = self.dailyHours
        self.hourlyHoursTextView.text = self.hourlyHours
    }
    
    // Clean escaped characters from JSON.
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
    
    /**
     @Params: Availability hours in JSON.
     @Returns: Availability hours in human-readable string.
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
    
    @IBAction func backButtonTapped(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
}
