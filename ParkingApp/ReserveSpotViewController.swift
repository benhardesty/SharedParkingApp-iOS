//
//  ReserveSpotViewController.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import UIKit
import JTAppleCalendar

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l < r
    case (nil, _?):
        return true
    default:
        return false
    }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
    switch (lhs, rhs) {
    case let (l?, r?):
        return l <= r
    default:
        return !(rhs < lhs)
    }
}


class ReserveSpotViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UIPopoverPresentationControllerDelegate, UITextFieldDelegate {
    
    // MARK: Outlets
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var requestReservationActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var imageIndexLabel: UILabel!
    @IBOutlet var addressTextField: UITextView!
    @IBOutlet var spotDetailsTextView: UITextView!
    @IBOutlet var spotHoursTextView: UITextView!
    @IBOutlet var hoursButton: UIButton!
    @IBOutlet var reservationTypeTextField: UITextField!
    @IBOutlet var monthlyStartLabel: UILabel!
    @IBOutlet var monthlyStartTextField: UITextField!
    @IBOutlet weak var monthlyRecurringSwitch: UISwitch!
    @IBOutlet weak var monthlyEndLabel: UILabel!
    @IBOutlet var startTextField: UITextField!
    @IBOutlet var endTextField: UITextField!
    @IBOutlet weak var hourlyStartTextField: UITextField!
    @IBOutlet weak var hourlyEndTextField: UITextField!
    @IBOutlet var reserveButton: UIButton!
    @IBOutlet var backToMapBarButton: UIBarButtonItem!
    @IBOutlet var calendarView: JTAppleCalendarView!
    @IBOutlet var monthLabel: UILabel!
    @IBOutlet weak var yearLabel: UILabel!
    @IBOutlet var totalPriceLabel: UILabel!
    @IBOutlet var monthlyStartUIView: UIView!
    @IBOutlet var dailyStartUIView: UIView!
    @IBOutlet var dailyEndUIView: UIView!
    @IBOutlet var hourlyStartUIView: UIView!
    @IBOutlet var hourlyEndUIView: UIView!
    @IBOutlet weak var agreementsTextView: UITextView!
    
    // MARK: Global Variables
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let testCalendar: Calendar! = Calendar(identifier: Calendar.Identifier.gregorian)
    let formatter = DateFormatter()
    
    var parkingSpot: ParkingSpot!
    var ipAddress:String!
    var picker:Int! = 0
    
    // Array of images
    var images = [UIImage]()
    
    // Current index in images array
    var imageIndex = 1
    //var spotAddress:String!
    
    // Array for UIPicker
    var reservationTypes = ["Monthly", "Daily", "Hourly"]
    
    // Type of spot user was filtering for on the map
    var filterType:String! = ""
    
    // UIPickerView
    let reservationTypePicker = UIPickerView()
    
    var spotID = ""
    
    var monthlyHoursString:String!
    var dailyHoursString:String!
    var hourlyHoursString:String = ""
    
    var monthlyHoursData:NSDictionary? = nil
    var dailyHoursData:NSDictionary? = nil
    var hourlyHoursData:NSDictionary? = nil
    
    var monthlyPrice:Double!
    var dailyPrice:Double!
    var hourlyPrice:Double!
    
    var reservations = [Reservation]()
    var unavailableDates = [Date]()
    var selectedDates = [Date]()
    var startDate:Date!
    var endDate:Date!
    var maxAvailableDate:Date!
    var minimumMonthlyDate:Date!
    
    // MARK: ViewDidLoad
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let calendar = Calendar.current
        let today = Date()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        
        setupCalendarView()
        
        ipAddress = appDelegate.ipAddress
        
        self.title = "Reserve Spot"
        self.navigationController?.navigationBar.barTintColor = appDelegate.colorPrimaryDark
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        
        // Set initial filter type for reservation based on map filter from last view.
        if(self.filterType != nil && self.filterType != "All") {
            self.reservationTypeTextField.text = self.filterType
        } else {
            self.reservationTypeTextField.text = self.reservationTypes[0]
        }
        
        minimumMonthlyDate = formatter.date(from: padString(input: String(calendar.component(.month, from: today))) + "/" + padString(input: String(calendar.component(.day, from:today))) + "/" + padString(input: String(calendar.component(.year, from: today))))
        minimumMonthlyDate = (calendar as NSCalendar).date(byAdding: .day, value: 1, to: minimumMonthlyDate, options: [])
        
        // Pull spot details and current reservation details from the server.
        loadSpotDetails()
        
        monthlyRecurringSwitch.isOn = true
        monthlyEndLabel.isHidden = true
        
        // Update the reservation
        reservationTypeChanged(self.reservationTypeTextField.text!)
        
        hoursButton.layer.borderWidth = 1
        hoursButton.layer.borderColor = UIColor.blue.cgColor
        
        // Create a UIToolBar for the 'done' button of the UIPickers
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 0, green: 0, blue: 200, alpha: 1)
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ReserveSpotViewController.donePicker))
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        // Initialize spotPicker resources
        reservationTypePicker.delegate = self
        reservationTypePicker.dataSource = self
        reservationTypeTextField.inputView = reservationTypePicker
        reservationTypeTextField.inputAccessoryView = toolBar
        
        hourlyStartTextField.delegate = self
        hourlyEndTextField.delegate = self
        
        // Add links to company's terms of service, privacy policy, and rental agreement.
        let attributedString = NSMutableAttributedString(string: "By clicking Request Reservation you agree to the XYZ Company Terms of Service and Privacy Policy and to the Rental Agreement.")
        let termsRange = attributedString.mutableString.range(of: "Terms of Service")
        if termsRange.location != NSNotFound {
            attributedString.addAttribute(NSLinkAttributeName, value: "", range: termsRange)
        }
        let privacyRange = attributedString.mutableString.range(of: "Privacy Policy")
        if privacyRange.location != NSNotFound {
            attributedString.addAttribute(NSLinkAttributeName, value: "", range: privacyRange)
        }
        let rentalRange = attributedString.mutableString.range(of: "Rental Agreement")
        if rentalRange.location != NSNotFound {
            attributedString.addAttribute(NSLinkAttributeName, value: "", range: rentalRange)
        }
        
        self.agreementsTextView.attributedText = attributedString
        
    }
    
    // Initialize cells of the availability calendar.
    func handleCell(view: JTAppleCell?, cellState: CellState, date: Date) {
        guard let validCell = view as? CustomJTAppleCell else { return }
        
        if !dateIsAvailable(date: date) {
            validCell.dateLabel.textColor = UIColor.black
            validCell.selectedView.isHidden = true
            validCell.unavailableView.isHidden = false
        } else {
            validCell.unavailableView.isHidden = true
            
            // Monthly or Daily
            if reservationTypeTextField.text == "Monthly" || reservationTypeTextField.text == "Daily" {
                if selectedDates.contains(date) {
                    validCell.dateLabel.textColor = UIColor.gray
                    validCell.selectedView.isHidden = false
                } else {
                    validCell.selectedView.isHidden = true
                    if cellState.dateBelongsTo == .thisMonth {
                        validCell.dateLabel.textColor = UIColor.white
                    } else {
                        validCell.dateLabel.textColor = UIColor.gray
                    }
                }
            } else { // Hourly
                let today = Date()
                let calendar = Calendar.current
                let todayString = "\(calendar.component(.month, from: today))/\(calendar.component(.day, from: today))/\(calendar.component(.year, from: today))"
                let dateString = "\(calendar.component(.month, from: date))/\(calendar.component(.day, from: date))/\(calendar.component(.year, from: date))"
                
                if todayString == dateString {
                    validCell.dateLabel.textColor = UIColor.gray
                    validCell.selectedView.isHidden = false
                } else {
                    validCell.selectedView.isHidden = true
                    if cellState.dateBelongsTo == .thisMonth {
                        validCell.dateLabel.textColor = UIColor.white
                    } else {
                        validCell.dateLabel.textColor = UIColor.gray
                    }
                }
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // returns the number of 'columns' to display.
    @available(iOS 2.0, *)
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // returns the # of rows in each component..
    @available(iOS 2.0, *)
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView == reservationTypePicker {
            return reservationTypes.count
        } else {
            return 0
        }
    }
    
    // Set the Spot_Type_Text_Field text to the selected row when a row is selected
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView == reservationTypePicker {
            reservationTypeTextField.text = reservationTypes[row]
            changeHoursText(reservationTypes[row])
            reservationTypeChanged(reservationTypes[row])
        }
    }
    
    // Title for row
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        if pickerView == reservationTypePicker {
            return reservationTypes[row]
        } else {
            return ""
        }
    }
    
    // Close keyboard.
    func donePicker(){
        reservationTypeTextField.resignFirstResponder()
    }
    
    @IBAction func monthlyStartTextFieldTapped(_ sender: UITextField) {
        
        // Identify which which date picker to use in the handleDatePicker method.
        picker = 2
        
        // Create a UIToolBar for the 'done' button of the UIPickers
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 0, green: 0, blue: 255, alpha: 1)
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ReserveSpotViewController.doneDatePicker))
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.date
        sender.inputView = datePickerView
        sender.inputAccessoryView = toolBar
        handleDatePicker(datePickerView)
        datePickerView.addTarget(self, action: #selector(ReserveSpotViewController.handleDatePicker(_:)), for: UIControlEvents.allEvents)
    }
    
    
    @IBAction func startTextFieldTapped(_ sender: UITextField) {
        
        // Identify which which date picker to use in the handleDatePicker method.
        picker = 0
        
        // Create a UIToolBar for the 'done' button of the UIPickers
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 0, green: 0, blue: 255, alpha: 1)
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ReserveSpotViewController.doneDatePicker))
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.date
        sender.inputView = datePickerView
        sender.inputAccessoryView = toolBar
        handleDatePicker(datePickerView)
        datePickerView.addTarget(self, action: #selector(ReserveSpotViewController.handleDatePicker(_:)), for: UIControlEvents.allEvents)
        
    }
    
    @IBAction func endTextFieldTapped(_ sender: UITextField) {
        
        // Identify which which date picker to use in the handleDatePicker method.
        picker = 1
        
        // Create a UIToolBar for the 'done' button of the UIPickers
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 0, green: 0, blue: 255, alpha: 1)
        toolBar.sizeToFit()
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(ReserveSpotViewController.doneDatePicker))
        toolBar.setItems([doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        
        let datePickerView: UIDatePicker = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.date
        sender.inputView = datePickerView
        sender.inputAccessoryView = toolBar
        handleDatePicker(datePickerView)
        datePickerView.addTarget(self, action: #selector(ReserveSpotViewController.handleDatePicker(_:)), for: UIControlEvents.valueChanged)
        
    }
    
    // Handle date picked from the date pickers.
    func handleDatePicker(_ sender: UIDatePicker) {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "MM/dd/yyyy"
        
        _ = Date()
        let calendar = Calendar.current
        let dateString = "\(calendar.component(.month, from: sender.date))/\(calendar.component(.day, from: sender.date))/\(calendar.component(.year, from: sender.date))"
        let date = timeFormatter.date(from: dateString)
        
        switch(picker){
        case 0:
            self.startDate = date
            startTextField.text = timeFormatter.string(from: date!)
            
            self.endDate = nil
            endTextField.text = ""
        case 1:
            
            if startDate == nil {
                displayMessage(message: "Please select start date", title: "Message")
                return
            }
            
            self.endDate = date
            
            endTextField.text = timeFormatter.string(from: sender.date)
        case 2:
            if maxAvailableDate == nil {
                monthlyStartTextField.text = timeFormatter.string(from: sender.date)
                self.startDate = date
                let monthlyEndDate = (calendar as NSCalendar).date(byAdding: .day, value: 30, to: date!, options: [])
                monthlyEndLabel.text = timeFormatter.string(from: monthlyEndDate!)
            } else {
                monthlyStartTextField.text = "Monthly Unavailable"
            }
        default:
            return
        }
        
        // Calculate prices based on dates selected.
        calculatePrice()
    }
    
    // Calculate prices based on current selected dates and reservation type.
    func calculatePrice() {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        _ = Calendar.current
        
        if parkingSpot == nil || reservationTypeTextField.text == "" {
            return
        }
        
        if reservationTypeTextField.text == "Monthly" {
            if monthlyStartTextField.text == "" {
                let price = "$0.00"
                totalPriceLabel.text = price
            } else {
                let rawPrice = parkingSpot.getMonthlyPrice()
                let price = "$" + String(format: "%.2f", rawPrice)
                totalPriceLabel.text = price
            }
        } else if reservationTypeTextField.text == "Daily" {
            if startTextField.text == "" || endTextField.text == "" {
                let price = "$0.00"
                totalPriceLabel.text = price
            } else {
                let start = formatter.date(from: startTextField.text!)
                let end = formatter.date(from: endTextField.text!)
                
                if end < start {
                    let price = "$0.00"
                    totalPriceLabel.text = price
                } else {
                    let diff = Double(Calendar.current.dateComponents([.day], from: start!, to: end!).day!) + 1.00
                    let rawPrice = parkingSpot.getDailyPrice() * diff
                    let price = "$" + String(format: "%.2f", rawPrice)
                    totalPriceLabel.text = price
                    
                }
            }
        } else if reservationTypeTextField.text == "Hourly" {
            if hourlyStartTextField.text == "" || hourlyEndTextField.text == "" {
                let price = "$0.00"
                totalPriceLabel.text = price
            } else {
                var start = Double(convert12to24(time: (hourlyStartTextField.text?.components(separatedBy: "today, ")[1])!).replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "30", with: "50"))
                var end = Double(convert12to24(time: (hourlyEndTextField.text?.components(separatedBy: "today, ")[1])!).replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "30", with: "50"))
                
                if start == 23.59 {
                    start = 24.00
                }
                
                if end == 23.59 {
                    end = 24.00
                }
                
                if end <= start {
                    let price = "$0.00"
                    totalPriceLabel.text = price
                } else {
                    let rawPrice = (end! - start!) * parkingSpot.getHourlyPrice()
                    let price = "$" + String(format: "%.2f", rawPrice)
                    totalPriceLabel.text = price
                }
            }
        }
    }
    
    // Close date pickers and reload calendar cells based on date selection.
    func doneDatePicker(){
        let datesToReload = self.selectedDates
        self.selectedDates.removeAll()
        self.reloadCalendarData(dates: datesToReload)
        
        switch reservationTypeTextField.text! {
        case "Monthly":
            if startDate != nil && maxAvailableDate == nil {
                self.selectedDates.append(startDate)
            }
            break
        case "Daily":
            if endDate != nil {
                if endDate < startDate {
                    displayMessage(message: "End date cannot be before start date", title: "Message")
                    return
                }
                
                let calendar = Calendar.current
                var currentDate = startDate
                while currentDate <= endDate {
                    self.selectedDates.append(currentDate!)
                    currentDate = (calendar as NSCalendar).date(byAdding: .day, value: 1, to: currentDate!, options: [])
                }
            } else {
                self.selectedDates.append(self.startDate)
            }
            break
        case "Hourly":
            break
        default:
            break
        }
        monthlyStartTextField.resignFirstResponder()
        startTextField.resignFirstResponder()
        endTextField.resignFirstResponder()
        
        self.reloadCalendarData(dates: self.selectedDates)
        
    }
    
    // Validate requested reservation against current availability.
    @IBAction func reserveButtonTapped(_ sender: UIButton) {
        let today = Date()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let todayDate = dateFormatter.date(from: String(calendar.component(.month, from: today)) + "/" + String(calendar.component(.day, from: today)) + "/" + String(calendar.component(.year, from: today)))
        
        switch reservationTypeTextField.text! {
        case "Monthly":
            
            if monthlyStartTextField.text! == "" || monthlyStartTextField.text == nil {
                displayMessage(message: "Please select a start date", title: "Message")
                return
            }
            
            let start = dateFormatter.date(from: monthlyStartTextField.text!)
            
            if start < todayDate {
                displayMessage(message: "Monthly start date must be after today.", title: "Message")
                return
            }
            
            if maxAvailableDate != nil {
                displayMessage(message: "Monthly reservations are unavailable.", title: "Message")
                return
            }
            
            if start < self.minimumMonthlyDate {
                displayMessage(message: "First available monthly reservation is on \(calendar.component(.month, from: minimumMonthlyDate))/\(calendar.component(.day, from: minimumMonthlyDate))/\(calendar.component(.year, from: minimumMonthlyDate))", title: "Message")
                return
            }
            
            if !dateIsAvailable(date: start!) {
                displayMessage(message: "The selected start date is unavailable.", title: "Message")
                return
            }
            
            break
        case "Daily":
            
            if startTextField.text == "" || startTextField.text == nil || endTextField.text == "" || endTextField.text == nil {
                displayMessage(message: "Start and end dates must be selected", title: "Message")
                return
            }
            
            let start = dateFormatter.date(from: startTextField.text!)
            let end = dateFormatter.date(from: endTextField.text!)
            
            if end < start {
                displayMessage(message: "End date cannot be before start date", title: "Message")
                return
            }
            
            if start <= todayDate {
                displayMessage(message: "Start date must be after today", title: "Message")
                return
            }
            
            if maxAvailableDate != nil {
                if end! > maxAvailableDate {
                    displayMessage(message: "One or more of the dates selected is unavailable", title: "Message")
                    return
                }
            }
            
            var currentDate = start
            
            while (currentDate <= end) {
                if !dateIsAvailable(date: currentDate!) {
                    displayMessage(message: "One or more of the dates selected is unavailable.", title: "Message")
                    return
                }
                currentDate = (calendar as NSCalendar).date(byAdding: .day, value: 1, to: currentDate!, options: [])
            }
            
            break
        case "Hourly":
            
            if hourlyStartTextField.text == "" || hourlyStartTextField.text == nil || hourlyEndTextField.text == "" || hourlyEndTextField.text == nil {
                displayMessage(message: "Start and end times must be selected.", title: "Message")
                return
            }
            
            let requestedStartTime = Int(convert12to24(time: (hourlyStartTextField.text?.components(separatedBy: "today, ")[1])!).replacingOccurrences(of: ":", with: ""))
            let requestedEndTime = Int(convert12to24(time: (hourlyEndTextField.text?.components(separatedBy: "today, ")[1])!).replacingOccurrences(of: ":", with: ""))
            
            if requestedEndTime <= requestedStartTime {
                displayMessage(message: "End time must be after start time.", title: "Message")
                return
            }
            
            let yearFirstDateFormatter = DateFormatter()
            yearFirstDateFormatter.dateFormat = "yyyy/MM/dd"
            
            for reservation in self.reservations {
                
                if reservation.getReservationType() == "Monthly" || reservation.getReservationType() == "Daily" {
                    
                    let reservationStart = yearFirstDateFormatter.date(from: reservation.getStart())
                    if reservationStart <= todayDate {
                        displayMessage(message: "This date is unavailable for hourly reservations", title: "Message")
                        return
                    }
                } else if reservation.getReservationType() == "Hourly" {
                    
                    let reservationStart = Int(reservation.getStart().components(separatedBy: "/")[3] + "" + reservation.getStart().components(separatedBy: "/")[4])
                    let reservationEnd = Int(reservation.getEnd().components(separatedBy: "/")[3] + "" + reservation.getEnd().components(separatedBy: "/")[4])
                    
                    if (requestedStartTime! >= reservationStart! && requestedStartTime! <= reservationEnd!) || (requestedEndTime! >= reservationStart! && requestedEndTime! <= reservationEnd!) || (requestedStartTime! < reservationStart! && requestedEndTime! >= reservationEnd!) {
                        displayMessage(message: "One or more of the times selected is unavailable", title: "Message")
                        return
                    }
                }
            }
            
            break
        default:
            break
        }
        
        // If reservation request validates against current data, send the request to the server.
        requestReservation()
    }
    
    // Send reservation request to the server.
    func requestReservation() {
        
        // Update UI to show request in process.
        self.requestReservationActivityIndicator.startAnimating()
        self.reserveButton.isEnabled = false
        self.reserveButton.backgroundColor = UIColor.lightGray
        
        let today = Date()
        let calendar = Calendar.current
        
        let spotID = self.spotID
        let reservationType = reservationTypeTextField.text!
        var start = ""
        var end = ""
        var hours = ""
        let totalPrice = totalPriceLabel.text!.replacingOccurrences(of: "$", with: "")
        let sessionid = UserDefaults.standard.object(forKey: "sessionid")
        
        // Prep data to send to server.
        switch reservationType {
        case "Monthly":
            let year = monthlyStartTextField.text?.components(separatedBy: "/")[2]
            let month = monthlyStartTextField.text?.components(separatedBy: "/")[0]
            let day = monthlyStartTextField.text?.components(separatedBy: "/")[1]
            start = year! + "/" + month! + "/" + day!
            
            if monthlyRecurringSwitch.isOn {
                end = "none"
            } else {
                let yearEnd = monthlyEndLabel.text?.components(separatedBy: "/")[2]
                let monthEnd = monthlyEndLabel.text?.components(separatedBy: "/")[0]
                let dayEnd = monthlyEndLabel.text?.components(separatedBy: "/")[1]
                end = yearEnd! + "/" + monthEnd! + "/" + dayEnd!
            }
            
            hours = self.parkingSpot.getMonthlyHours().replacingOccurrences(of: "&quot;", with: "\"", options: NSString.CompareOptions.literal, range: nil)
            
            break
        case "Daily":
            let yearStart = startTextField.text?.components(separatedBy: "/")[2]
            let monthStart = startTextField.text?.components(separatedBy: "/")[0]
            let dayStart = startTextField.text?.components(separatedBy: "/")[1]
            start = yearStart! + "/" + monthStart! + "/" + dayStart!
            
            let yearEnd = endTextField.text?.components(separatedBy: "/")[2]
            let monthEnd = endTextField.text?.components(separatedBy: "/")[0]
            let dayEnd = endTextField.text?.components(separatedBy: "/")[1]
            end = yearEnd! + "/" + monthEnd! + "/" + dayEnd!
            
            hours = self.parkingSpot.getDailyHours().replacingOccurrences(of: "&quot;", with: "\"", options: NSString.CompareOptions.literal, range: nil)
            
            break
        case "Hourly":
            let todayString = padString(input: String(calendar.component(.year, from: today))) + "/" + padString(input: String(calendar.component(.month, from: today))) + "/" + padString(input: String(calendar.component(.day, from: today)))
            start = todayString + "/" + convert12to24(time: hourlyStartTextField.text!.components(separatedBy: "today, ")[1]).replacingOccurrences(of: ":", with: "/")
            end = todayString + "/" + convert12to24(time: hourlyEndTextField.text!.components(separatedBy: "today, ")[1]).replacingOccurrences(of: ":", with: "/")
            
            hours = self.parkingSpot.getHourlyHours().replacingOccurrences(of: "&quot;", with: "\"", options: NSString.CompareOptions.literal, range: nil)
            
            break
        default:
            break
        }
        
        // Send request to server.
        let myURL = URL(string: "https://" + ipAddress + "")
        let postString = "spotID=\(spotID)&sessionid=\(sessionid!)&start=\(start)&end=\(end)&totalPrice=\(totalPrice)&spotAddress=\(self.parkingSpot.getSpotAddress())&reservationType=\(reservationType)&access=\(self.parkingSpot.getAccessType())&hours=\(hours)"
        let request = NSMutableURLRequest(url: myURL!)
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if(data == nil) {
                let messageToDisplay:String = "Please try again."
                let alert = UIAlertController(title: "Alert", message: messageToDisplay, preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
                alert.addAction(okAction)
                
                DispatchQueue.main.async(execute: {
                    self.present(alert, animated: true, completion: nil)
                })
                
                return
            }
            
            do{
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    
                    let resultValue = parseJSON["status"] as? String
                    
                    if(resultValue == "Success") {
                        
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
                                okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
                            }
                            
                            alert.addAction(okAction)
                            self.requestReservationActivityIndicator.stopAnimating()
                            self.reserveButton.isEnabled = true
                            self.reserveButton.backgroundColor = self.appDelegate.colorAccent
                            
                            self.present(alert, animated: true, completion: nil)
                            
                        })
                        
                    } else if resultValue == "PaymentMissing" {
                        
                        let messageToDisplay:String = parseJSON["message"] as! String
                        
                        DispatchQueue.main.async(execute: {
                            
                            // Display alert message with confirmation
                            let alert = UIAlertController(title: "Alert", message: messageToDisplay, preferredStyle: UIAlertControllerStyle.alert)
                            
                            var okAction: UIAlertAction
                            
                            okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
                            
                            alert.addAction(okAction)
                            self.requestReservationActivityIndicator.stopAnimating()
                            self.reserveButton.isEnabled = true
                            self.reserveButton.backgroundColor = self.appDelegate.colorAccent
                            
                            self.present(alert, animated: true, completion: nil)
                            
                        })
                    } else {
                        self.requestReservationActivityIndicator.stopAnimating()
                        let messageToDisplay:String = parseJSON["message"] as! String
                        
                        if messageToDisplay == "Please log in." {
                            self.appDelegate.logoutFunction()
                        }
                        
                        DispatchQueue.main.async(execute: {
                            
                            // Display alert message with confirmation
                            let alert = UIAlertController(title: "Alert", message: messageToDisplay, preferredStyle: UIAlertControllerStyle.alert)
                            
                            var okAction: UIAlertAction
                            
                            okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
                            
                            alert.addAction(okAction)
                            self.requestReservationActivityIndicator.stopAnimating()
                            self.reserveButton.isEnabled = true
                            self.reserveButton.backgroundColor = self.appDelegate.colorAccent
                            
                            self.present(alert, animated: true, completion: nil)
                            
                        })
                    }
                    
                }
            } catch _ as NSError {
            }
            
        }
        task.resume()
    }
    
    // Load spot details and current reservations.
    func loadSpotDetails() {
        
        activityIndicator.startAnimating()
        
        let myURL = URL(string: "https://" + ipAddress + "")
        let spotID = self.spotID
        let postString = "spotID=\(spotID)"
        let request = NSMutableURLRequest(url: myURL!)
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            // No response from server or no data from server.
            if(data == nil) {
                let messageToDisplay:String = "Oops! Spot details weren't loaded! Please go back to the map and click the spot again!"
                let alert = UIAlertController(title: "Alert", message: messageToDisplay, preferredStyle: UIAlertControllerStyle.alert)
                let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
                alert.addAction(okAction)
                DispatchQueue.main.async(execute: {
                    self.present(alert, animated: true, completion: nil)
                })
                return
            }
            
            do{
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    
                    let resultValue = parseJSON["status"] as? String
                    
                    if(resultValue == "Success") {
                        
                        let data = parseJSON["data"] as! [String:AnyObject]
                        
                        self.parkingSpot = ParkingSpot(spot: data )
                        
                        self.monthlyHoursData = self.parseHoursData(self.parkingSpot.getMonthlyHours())
                        self.dailyHoursData = self.parseHoursData(self.parkingSpot.getDailyHours())
                        self.hourlyHoursData = self.parseHoursData(self.parkingSpot.getHourlyHours())
                        
                        self.monthlyHoursString = self.generateHoursStringFromJSON(self.monthlyHoursData as! [String : AnyObject])
                        self.dailyHoursString = self.generateHoursStringFromJSON(self.dailyHoursData as! [String : AnyObject])
                        self.hourlyHoursString = self.generateHoursStringFromJSON(self.hourlyHoursData as! [String : AnyObject])
                        
                        var prices:String! = "Prices -"
                        
                        self.reservationTypes = []
                        
                        if(self.parkingSpot.getAvailableMonthly() == 1){
                            self.reservationTypes.append("Monthly")
                            prices = prices + "\nMonthly: \(self.parkingSpot.getMonthlyPrice())"
                            self.monthlyPrice = Double(self.parkingSpot.getMonthlyPrice())
                        }
                        if(self.parkingSpot.getAvailableDaily() == 1){
                            self.reservationTypes.append("Daily")
                            prices = prices + "\nDaily: \(self.parkingSpot.getDailyPrice())"
                            self.dailyPrice = Double(self.parkingSpot.getDailyPrice())
                        }
                        if(self.parkingSpot.getAvailableHourly() == 1){
                            self.reservationTypes.append("Hourly")
                            prices = prices + "\nHourly: \(self.parkingSpot.getHourlyPrice())"
                            self.hourlyPrice = Double(self.parkingSpot.getHourlyPrice())
                        }
                        
                        let spotDetails = "Spot Type: \(self.parkingSpot.getSpotType())\nAccess: \(self.parkingSpot.getAccessType())\n\(prices!)\nUser Rating: \(self.parkingSpot.getSpotRating())"
                        
                        var spotHours:String!
                        
                        var reservationType = ""
                        
                        if(self.reservationTypes.contains(self.filterType)) {
                            switch (self.filterType) {
                            case "Monthly":
                                reservationType = "Monthly"
                                spotHours = "Monthly Hours:\n" + self.monthlyHoursString
                            case "Daily":
                                reservationType = "Daily"
                                spotHours = "Daily Hours:\n" + self.dailyHoursString
                            case "Hourly":
                                reservationType = "Hourly"
                                spotHours = "Hourly Hours:\n" + self.hourlyHoursString
                            default:
                                break
                            }
                        } else {
                            switch (self.reservationTypes[0]) {
                            case "Monthly":
                                reservationType = "Monthly"
                                spotHours = "Monthly Hours:\n" + self.monthlyHoursString
                            case "Daily":
                                reservationType = "Daily"
                                spotHours = "Daily Hours:\n" + self.dailyHoursString
                            case "Hourly":
                                reservationType = "Hourly"
                                spotHours = "Hourly Hours:\n" + self.hourlyHoursString
                            default:
                                break
                            }
                        }
                        
                        DispatchQueue.main.async(execute: {
                            self.addressTextField.text = self.parkingSpot.getSpotAddress()
                            self.spotDetailsTextView.text = spotDetails
                            self.spotHoursTextView.text = spotHours
                            self.reservationTypeTextField.text = reservationType
                            self.reservationTypeChanged(reservationType)
                            self.downloadImages()
                        })
                        
                    }
                    
                    let reservationsStatus = parseJSON["reservationsStatus"] as? String
                    
                    // Handle reservations returned by the server for this spot.
                    if(reservationsStatus == "Success") {
                        
                        let reservationsData = parseJSON["reservationsData"] as! [[String : AnyObject]]
                        
                        let today = Date()
                        let calendar = Calendar.current
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy/MM/dd"
                        let todayDate = dateFormatter.date(from: String(calendar.component(.year, from: today)) + "/" + String(calendar.component(.month, from: today)) + "/" + String(calendar.component(.day, from: today)))
                        
                        for data in reservationsData {
                            
                            let reservation: Reservation = Reservation(reservation: data)
                            self.reservations.append(reservation)
                            
                            // Adjust availability based on reservation.
                            switch reservation.getReservationType() {
                            case "Monthly":
                                if reservation.getEnd() == "none" {
                                    self.maxAvailableDate = dateFormatter.date(from: reservation.getStart())
                                    let calendar = Calendar.current
                                    self.maxAvailableDate = (calendar as NSCalendar).date(byAdding: .day, value: -1, to: self.maxAvailableDate!, options: [])
                                    
                                    self.monthlyStartTextField.text = "Monthly Unavailable"
                                    
                                } else {
                                    var reservationStartDate = dateFormatter.date(from: reservation.getStart())
                                    let reservationEndDate  = dateFormatter.date(from: reservation.getEnd())
                                    
                                    if reservationEndDate! > self.minimumMonthlyDate {
                                        self.minimumMonthlyDate = (calendar as NSCalendar).date(byAdding: .day, value: 1, to: reservationEndDate!, options: [])
                                    }
                                    
                                    let calendar = Calendar.current
                                    while (reservationStartDate <= reservationEndDate) {
                                        self.unavailableDates.append(reservationStartDate!)
                                        reservationStartDate = (calendar as NSCalendar).date(byAdding: .day, value: 1, to: reservationStartDate!, options: [])
                                    }
                                }
                            case "Daily":
                                var reservationStartDate = dateFormatter.date(from: reservation.getStart())
                                let reservationEndDate  = dateFormatter.date(from: reservation.getEnd())
                                
                                if reservationEndDate! > self.minimumMonthlyDate {
                                    self.minimumMonthlyDate = (calendar as NSCalendar).date(byAdding: .day, value: 1, to: reservationEndDate!, options: [])
                                }
                                
                                let calendar = Calendar.current
                                while (reservationStartDate <= reservationEndDate) {
                                    self.unavailableDates.append(reservationStartDate!)
                                    reservationStartDate = (calendar as NSCalendar).date(byAdding: .day, value: 1, to: reservationStartDate!, options: [])
                                }
                                break
                            case "Hourly":
                                let reservationEnd = Int(reservation.getEnd().components(separatedBy: "/")[3] + "" + reservation.getEnd().components(separatedBy: "/")[4])
                                let currentTime = Int(self.padString(input: String(calendar.component(.hour, from: today))) + "" + self.padString(input: String(calendar.component(.minute, from: today))))
                                
                                if currentTime! <= reservationEnd! {
                                    self.unavailableDates.append(todayDate!)
                                }
                                break
                            default:
                                break
                            }
                        }
                        
                        DispatchQueue.main.async(execute: {
                            
                            // Update calendar with the new available dates.
                            if (self.unavailableDates.count > 0) {
                                self.calendarView.reloadData()
                            }
                        })
                    }
                    
                }
            } catch _ as NSError {
            }
        }
        task.resume()
    }
    
    // Download the spot's images from the server.
    func downloadImages() {
        
        let urlArray = parkingSpot.getPhotos().components(separatedBy: ",")
        let numofimages = urlArray.count
        var currentimageindex = 1
        let maxWidth = self.imageView.frame.width
        
        for url in urlArray {
            
            let url = URL(string: "https://" + ipAddress + "")
            
            _ = URLSession.shared.dataTask(with: url!, completionHandler: {
                data, response, error in
                
                if data == nil {
                    DispatchQueue.main.async(execute: {
                        
                        let messageToDisplay:String = "Error. No data."
                        
                        // Display alert message with confirmation.
                        let alert = UIAlertController(title: "Alert", message: messageToDisplay, preferredStyle: UIAlertControllerStyle.alert)
                        
                        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
                        
                        alert.addAction(okAction)
                        
                        self.present(alert, animated: true, completion: nil)
                    })
                }
                
                self.images.append(UIImage(data: NSData(data: data!) as Data)!.resized(toWidth: maxWidth)!)
                
                DispatchQueue.main.async(execute: {
                    
                    self.imageView.image = self.images[0]
                    
                    if currentimageindex == numofimages {
                        
                        self.updateImageIndexLabel()
                        self.activityIndicator.stopAnimating()
                    }
                    currentimageindex += 1
                })
                
            }) .resume()
        }
    }
    
    // Scroll to the image on the right, if there is one.
    @IBAction func scrollImageRight(_ sender: UIButton) {
        if(imageIndex < (images.count)) {
            imageIndex += 1
            imageView.image = images[imageIndex - 1]
            updateImageIndexLabel()
        }
    }
    
    // Scroll to the image on the left, if there is one.
    @IBAction func scrollImageLeft(_ sender: UIButton) {
        if(imageIndex > 1) {
            imageIndex -= 1
            imageView.image = images[imageIndex - 1]
            updateImageIndexLabel()
        }
    }
    
    // Update the text on the imageIndexLabel to reflect what image the user is seeing and how many images there currently are.
    func updateImageIndexLabel(){
        imageIndexLabel.text = "\(imageIndex) of \(images.count)"
    }
    
    // Clean escaped characters.
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
    
    /*
     @Params: a number in the format of a string
     @Returns: a string with a leading 0 if there was originally only 1 character
     */
    func padString(input: String) -> String {
        
        if input.characters.count < 2 {
            return "0" + input
        }
        
        return input
    }
    
    /*
     @Params: time in format "HH:MM XX"in 12 hour format, where XX is 'AM' or 'PM'
     @Returns: time in format "HH:MM" in 24 hour format
     */
    func convert12to24(time:String) -> String {
        
        if time.components(separatedBy: " ")[1] == "AM" {
            if time.components(separatedBy: " ")[0].components(separatedBy: ":")[0] == "12" {
                return ("00:" + time.components(separatedBy: " ")[0].components(separatedBy: ":")[1])
            }
            return time.components(separatedBy: " ")[0]
        } else {
            if time.components(separatedBy: " ")[0].components(separatedBy: ":")[0] == "12" {
                return time.components(separatedBy: " ")[0]
            }
            return String(Int(time.components(separatedBy: " ")[0].components(separatedBy: ":")[0])! + 12) + ":" + time.components(separatedBy: " ")[0].components(separatedBy: ":")[1]
        }
    }
    
    // Update UI based on user changing the reservation type.
    func reservationTypeChanged(_ reservationType:String) {
        
        self.startDate = nil
        self.endDate = nil
        self.selectedDates.removeAll()
        startTextField.text = ""
        endTextField.text = ""
        monthlyStartTextField.text = ""
        monthlyEndLabel.text = ""
        hourlyStartTextField.text = ""
        hourlyEndTextField.text = ""
        
        switch (reservationType) {
        case "Monthly":
            monthlyStartUIView.isHidden = false
            dailyStartUIView.isHidden = true
            dailyEndUIView.isHidden = true
            hourlyStartUIView.isHidden = true
            hourlyEndUIView.isHidden = true
            if maxAvailableDate != nil {
                monthlyStartTextField.text = "Monthly Unavailable"
            }
            break
        case "Daily":
            monthlyStartUIView.isHidden = true
            dailyStartUIView.isHidden = false
            dailyEndUIView.isHidden = false
            hourlyStartUIView.isHidden = true
            hourlyEndUIView.isHidden = true
            break
        case "Hourly":
            let today = Date()
            
            monthlyStartUIView.isHidden = true
            dailyStartUIView.isHidden = true
            dailyEndUIView.isHidden = true
            hourlyStartUIView.isHidden = false
            hourlyEndUIView.isHidden = false
            
            if unavailableDates.contains(today) {
                displayMessage(message: "Hourly reservations are currently unavailable", title: "Message")
            }
            break
        default:
            break
        }
        
        calculatePrice()
        
        self.calendarView.reloadData()
    }
    
    // Update availability based on reservatio type selected.
    func changeHoursText(_ hours:String) {
        
        var spotHours:String
        
        switch (hours) {
        case "Monthly":
            spotHours = "Monthly Hours:\n" + self.monthlyHoursString
        case "Daily":
            spotHours = "Daily Hours:\n" + self.dailyHoursString
        case "Hourly":
            spotHours = "Hourly Hours:\n" + self.hourlyHoursString
        default:
            switch (self.reservationTypes[0]) {
            case "Monthly":
                spotHours = "Monthly Hours:\n" + self.monthlyHoursString
            case "Daily":
                spotHours = "Daily Hours:\n" + self.dailyHoursString
            case "Hourly":
                spotHours = "Hourly Hours:\n" + self.hourlyHoursString
            default:
                spotHours = "Monthly Hours:\n" + self.monthlyHoursString
            }
        }
        
        self.spotHoursTextView.text = spotHours
    }
    
    @IBAction func monthlyRecurringSwitchChanged(_ sender: Any) {
        if monthlyRecurringSwitch.isOn {
            monthlyEndLabel.isHidden = true
        } else {
            monthlyEndLabel.isHidden = false
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        
        if(segue.identifier == "additionalHours") {
            // Get the new view controller using segue.destinationViewController.
            // Pass the selected object to the new view controller.
            
            let nav = segue.destination as! UINavigationController
            let destinationSegue = nav.topViewController as! AdditionalHoursViewController
            
            destinationSegue.monthlyHours = self.monthlyHoursString
            destinationSegue.dailyHours = self.dailyHoursString
            destinationSegue.hourlyHours = self.hourlyHoursString
        }
        
        if(segue.identifier == "showHourlyStartPopover") {
            // Get the new view controller using segue.destinationViewController.
            // Pass the selected object to the new view controller.
            
            let popoverViewController = segue.destination as! HourlyHoursViewController
            popoverViewController.reservations = self.reservations
            popoverViewController.unavailableDates = self.unavailableDates
            popoverViewController.startOrEnd = "Start"
            popoverViewController.hoursData = parkingSpot.getHourlyHours()
            popoverViewController.popoverPresentationController?.delegate = self
        }
        
        if(segue.identifier == "showHourlyEndPopover") {
            // Get the new view controller using segue.destinationViewController.
            // Pass the selected object to the new view controller.
            
            let popoverViewController = segue.destination as! HourlyHoursViewController
            popoverViewController.reservations = self.reservations
            popoverViewController.unavailableDates = self.unavailableDates
            popoverViewController.startOrEnd = "End"
            popoverViewController.hoursData = parkingSpot.getHourlyHours()
            popoverViewController.popoverPresentationController?.delegate = self
        }
        
    }
    @IBAction func showHourlyStartPopover(_ sender: Any) {
        performSegue(withIdentifier: "showHourlyStartPopover", sender: nil)
    }
    
    @IBAction func showHourlyEndPopover(_ sender: Any) {
        performSegue(withIdentifier: "showHourlyEndPopover", sender: nil)
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    @IBAction func unwindToReserveSpotViewController(_ unwindSegue: UIStoryboardSegue){
    }
    
    @IBAction func unwindToReserveSpotFromHourlyHours(_ unwindSegue: UIStoryboardSegue){
        
        if let hourlyHoursSegue = unwindSegue.source as? HourlyHoursViewController {
            
            if hourlyHoursSegue.startOrEnd == "Start" {
                hourlyStartTextField.text = hourlyHoursSegue.selectedHour
            } else if hourlyHoursSegue.startOrEnd == "End" {
                hourlyEndTextField.text = hourlyHoursSegue.selectedHour
            }
            
            calculatePrice()
        }
    }
    
    @IBAction func backToMapButtonTapped(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    // Disable default editing and perform segue instead.
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == hourlyStartTextField {
            showHourlyStartPopover(textField)
            return false
        }
        
        if textField == hourlyEndTextField {
            showHourlyEndPopover(textField)
            return false
        }
        
        return true
    }
    
    func displayMessage(message: String, title: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func setupCalendarView() {
        // Setup calendar spacing
        calendarView.minimumLineSpacing = 0
        calendarView.minimumInteritemSpacing = 0
        
        // Setup labels
        calendarView.visibleDates{ (visibleDates) in
            self.setupViewsOfCalendar(from: visibleDates)
        }
    }
    
    func setupViewsOfCalendar(from visibleDates: DateSegmentInfo) {
        let date = visibleDates.monthDates.first!.date
        
        formatter.dateFormat = "yyyy"
        yearLabel.text = formatter.string(from: date)
        
        formatter.dateFormat = "MMMM"
        monthLabel.text = formatter.string(from: date)
    }
    
    // Return whether a date is greater than the max available date.
    func dateGreaterThanMaxDate(date: Date) -> Bool {
        if (self.maxAvailableDate) != nil {
            if date > self.maxAvailableDate {
                return true
            }
            return false
        } else {
            return false
        }
    }
    
    // Return if a date is available.
    func dateIsAvailable(date: Date) -> Bool {
        
        if unavailableDates.contains(date) { // Date is unavailable
            return false
        }
        if dateGreaterThanMaxDate(date: date) { // Date is unavailable
            return false
        }
        
        let today = Date()
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let todayDate = dateFormatter.date(from: String(calendar.component(.month, from: today)) + "/" + String(calendar.component(.day, from: today)) + "/" + String(calendar.component(.year, from: today)))
        
        let dayOfWeek = calendar.component(.weekday, from: date)
        var day = ""
        
        switch dayOfWeek {
        case 1:
            day = "sunday"
            break
        case 2:
            day = "monday"
            break
        case 3:
            day = "tuesday"
            break
        case 4:
            day = "wednesday"
            break
        case 5:
            day = "thursday"
            break
        case 6:
            day = "friday"
            break
        case 7:
            day = "saturday"
            break
        default:
            break
        }
        
        let switchName = day + "Switch"
        let dayFrom = day + "From"
        let dayTo = day + "To"
        
        var json:NSDictionary!
        
        let reservationType = self.reservationTypeTextField.text!
        
        switch reservationType {
        case "Monthly":
            json = monthlyHoursData
            break
        case "Daily":
            json = dailyHoursData
            break
        case "Hourly":
            json = hourlyHoursData
            break
        default:
            return false
        }
        
        if json == nil {
            return true
        }
        
        if json[switchName] as! String == "false" {
            return false
        }
        
        if date == todayDate {
            let currentTime = Int(padString(input: String(calendar.component(.hour, from: today))) + padString(input: String(calendar.component(.minute, from: today))))
            let availableFrom = Int(convert12to24(time: json[dayFrom]! as! String).replacingOccurrences(of: ":", with: ""))
            let availableTo = Int(convert12to24(time: json[dayTo]! as! String).replacingOccurrences(of: ":", with: ""))
            
            if currentTime! < availableFrom! || currentTime! > availableTo! {
                return false
            }
        }
        
        return true
    }
    
    
    
}

// MARK: JTAppleCalendarDelegate
extension ReserveSpotViewController: JTAppleCalendarViewDataSource {
    
    
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        formatter.dateFormat = "yyyy MM dd"
        formatter.timeZone = Calendar.current.timeZone
        formatter.locale = Calendar.current.locale
        
        let calendar = Calendar.current
        let calendarStart = Date()
        let calendarEnd = (calendar as NSCalendar).date(byAdding: .year, value: 1, to: calendarStart, options: [])
        
        let parameters = ConfigurationParameters(startDate: calendarStart, endDate: calendarEnd!)
        return parameters
    }
}

extension ReserveSpotViewController: JTAppleCalendarViewDelegate  {
    
    // Display the cell.
    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "CustomJTAppleCell", for: indexPath) as! CustomJTAppleCell
        
        cell.dateLabel.text = cellState.text
        
        handleCell(view: cell, cellState: cellState, date: date)
        
        return cell
    }
    
    // Date selected.
    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "MM/dd/yyyy"
        
        switch reservationTypeTextField.text! {
        case "Monthly":
            let calendar = Calendar.current
            let datesToReload = self.selectedDates
            self.selectedDates.removeAll()
            self.reloadCalendarData(dates: datesToReload)
            if unavailableDates.contains(date) {
                displayMessage(message: "Date is unavailable", title: "Error")
                return
            }
            
            startDate = date
            
            if maxAvailableDate != nil {
                monthlyStartTextField.text = "Monthly Unavailable"
            } else {
                monthlyStartTextField.text = timeFormatter.string(from: startDate)
                let monthlyEndDate = (calendar as NSCalendar).date(byAdding: .day, value: 30, to: date, options: [])
                monthlyEndLabel.text = timeFormatter.string(from: monthlyEndDate!)
                calculatePrice()
            }
            
            self.selectedDates.append(date)
            break
        case "Daily":
            if startDate == nil {
                self.selectedDates.removeAll()
                startDate = date
                self.selectedDates.append(startDate)
                
                startTextField.text = timeFormatter.string(from: startDate)
                calculatePrice()
            } else if endDate == nil {
                
                if date < startDate {
                    displayMessage(message: "End date cannot be before start date.", title: "Error")
                    return
                }
                
                self.selectedDates.removeAll()
                
                endDate = date
                
                endTextField.text = timeFormatter.string(from: endDate)
                calculatePrice()
                
                let calendar = Calendar.current
                var currentDate = startDate
                while currentDate <= endDate {
                    self.selectedDates.append(currentDate!)
                    currentDate = (calendar as NSCalendar).date(byAdding: .day, value: 1, to: currentDate!, options: [])
                }
            } else {
                let datesToReload = self.selectedDates
                self.selectedDates.removeAll()
                self.reloadCalendarData(dates: datesToReload)
                startDate = nil
                endDate = nil
                
                startTextField.text = ""
                endTextField.text = ""
            }
            break
        case "Hourly":
            self.selectedDates.removeAll()
            break
        default:
            break
        }
        
        self.reloadCalendarData(dates: self.selectedDates)
        
    }
    
    func reloadCalendarData(dates: [Date]) {
        self.calendarView.reloadDates(dates)
    }
    
    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        
        setupViewsOfCalendar(from: visibleDates)
    }
}

extension UIImage {
    func resized(withPercentage percentage: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: size.width * percentage, height: size.height * percentage)
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    func resized(toWidth width: CGFloat) -> UIImage? {
        let canvasSize = CGSize(width: width, height: CGFloat(ceil(width/size.width * size.height)))
        UIGraphicsBeginImageContextWithOptions(canvasSize, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: canvasSize))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
