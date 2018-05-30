//
//  AdditionalHoursViewController.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import UIKit

class AdditionalHoursViewController: UIViewController {
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var monthlyHoursTextView: UITextView!
    @IBOutlet var dailyHoursTextView: UITextView!
    @IBOutlet var hourlyHoursTextView: UITextView!
    
    var monthlyHours:String! = ""
    var dailyHours:String! = ""
    var hourlyHours:String! = ""
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = appDelegate.colorPrimaryDark
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        self.title = "Hours"
        scrollView.contentSize.height = 486
        
        if(monthlyHours == "") {
            monthlyHoursTextView.text = "Not Available"
        } else {
            monthlyHoursTextView.text = monthlyHours
        }
        
        if(dailyHours == "") {
            dailyHoursTextView.text = "Not Available"
        } else {
            dailyHoursTextView.text = dailyHours
        }
        
        if(hourlyHours == "") {
            hourlyHoursTextView.text = "Not Available"
        } else {
            hourlyHoursTextView.text = hourlyHours
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}
