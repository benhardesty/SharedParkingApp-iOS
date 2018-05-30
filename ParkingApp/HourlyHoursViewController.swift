//
//  HourlyHoursViewController.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import UIKit

class HourlyHoursViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var hours = ["today, 12:00 AM", "today, 12:30 AM", "today, 01:00 AM", "today, 01:30 AM", "today, 02:00 AM", "today, 02:30 AM", "today, 03:00 AM", "today, 03:30 AM", "today, 04:00 AM", "today, 04:30 AM", "today, 05:00 AM", "today, 05:30 AM", "today, 06:00 AM", "today, 06:30 AM", "today, 07:00 AM", "today, 07:30 AM", "today, 08:00 AM", "today, 08:30 AM", "today, 09:00 AM", "today, 09:30 AM", "today, 10:00 AM", "today, 10:30 AM", "today, 11:00 AM", "today, 11:30 AM", "today, 12:00 PM", "today, 12:30 PM", "today, 01:00 PM", "today, 01:30 PM", "today, 02:00 PM", "today, 02:30 PM", "today, 03:00 PM", "today, 03:30 PM", "today, 04:00 PM", "today, 04:30 PM", "today, 05:00 PM", "today, 05:30 PM", "today, 06:00 PM", "today, 06:30 PM", "today, 07:00 PM", "today, 07:30 PM", "today, 08:00 PM", "today, 08:30 PM", "today, 09:00 PM", "today, 09:30 PM", "today, 10:00 PM", "today, 10:30 PM", "today, 11:00 PM", "today, 11:30 PM", "today, 11:59 PM"]
    
    var reservations = [Reservation]()
    
    var unavailableDates = [Date]()
    
    var hoursData:String!
    
    var rowSelected:Int!
    
    var startOrEnd:String!
    
    var selectedHour:String!
    
    var availableFrom:Int!
    
    var availableTo:Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let hoursJSON = self.parseHoursData(hoursData)
        
        self.setAvailabilityFromAndTo(hoursJSON as! [String : AnyObject])
        
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.lightGray.cgColor
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PendingRequestCell.self, forCellReuseIdentifier: "HourlyHoursCell")
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return hours.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell:UITableViewCell?
        
        cell = tableView.dequeueReusableCell(withIdentifier: "HourlyHoursCell", for: indexPath)
        cell?.textLabel!.text = hours[indexPath.row]
        
        if(timeIsAvailable(time: hours[indexPath.row].components(separatedBy: "today, ")[1])){
            cell?.backgroundColor = UIColor.white
            cell?.textLabel!.textColor = UIColor.black
            cell?.isUserInteractionEnabled = true
        } else {
            cell?.backgroundColor = UIColor.lightGray
            cell?.textLabel!.textColor = UIColor.gray
            cell?.isUserInteractionEnabled = false
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.rowSelected = indexPath.row
        
        if(timeIsAvailable(time: hours[indexPath.row].components(separatedBy: "today, ")[1])){
            selectedHour = hours[indexPath.row]
            performSegue(withIdentifier: "unwindToReserveSpotFromHourlyHours", sender: nil)
        } else {
            
        }
    }
    
    func setAvailabilityFromAndTo(_ json: [String : AnyObject]) {
        
        let today = Date()
        let calendar = Calendar.current
        
        let dayOfWeek = calendar.component(.weekday, from: today)
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
        
        if(json[switchName] as! String == "true") {
            availableFrom = Int(convert12to24(time: json[dayFrom]! as! String).replacingOccurrences(of: ":", with: ""))
            availableTo = Int(convert12to24(time: json[dayTo]! as! String).replacingOccurrences(of: ":", with: ""))
        } else {
            availableFrom = nil
            availableTo = nil
        }
        
    }
    
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
     @Params: time in format "HH:MM XX"in 12 hour format, where XX is 'AM' or 'PM'
     @Returns: true if the time is available, false if the time is not available. Availability is determined by the current reservations in the reservations array
     */
    func timeIsAvailable(time: String) -> Bool {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        
        let today = Date()
        let calendar = Calendar.current
        
        _ = formatter.date(from: String(calendar.component(.month, from: today)) + "/" + String(calendar.component(.day, from: today)) + "/" + String(calendar.component(.year, from: today)))
        let requestedTime = Int(convert12to24(time: time).replacingOccurrences(of: ":", with: ""))
        let currentTime = Int(padString(input: String(calendar.component(.hour, from: today))) + "" + padString(input: String(calendar.component(.minute, from: today))))
        
        if availableFrom == nil || availableTo == nil {
            return false
        }
        
        if requestedTime! < availableFrom || requestedTime! > availableTo {
            return false
        }
        
        if requestedTime! < currentTime! {
            return false
        }
        
        for reservation in reservations {
            if reservation.getReservationType() == "Hourly" {
                let reservationStart = Int(reservation.getStart().components(separatedBy: "/")[3] + "" + reservation.getStart().components(separatedBy: "/")[4])
                let reservationEnd = Int(reservation.getEnd().components(separatedBy: "/")[3] + "" + reservation.getEnd().components(separatedBy: "/")[4])
                
                if requestedTime! >= reservationStart! && requestedTime! <= reservationEnd! {
                    return false
                }
            } else if reservation.getReservationType() == "Daily" {
                let currentDate = Int(padString(input: String(calendar.component(.year, from: today))) + "" + padString(input: String(calendar.component(.month, from: today))) + "" + padString(input: String(calendar.component(.day, from: today))))
                let reservationStartYear = reservation.getStart().components(separatedBy: "/")[0]
                let reservationStartMonth = reservation.getStart().components(separatedBy: "/")[1]
                let reservationStartDay = reservation.getStart().components(separatedBy: "/")[2]
                let reservationStart = Int(padString(input: reservationStartYear) + padString(input: reservationStartMonth) + padString(input: reservationStartDay))
                
                let reservationEndYear = reservation.getEnd().components(separatedBy: "/")[0]
                let reservationEndMonth = reservation.getEnd().components(separatedBy: "/")[1]
                let reservationEndDay = reservation.getEnd().components(separatedBy: "/")[2]
                let reservationEnd = Int(padString(input: reservationEndYear) + padString(input: reservationEndMonth) + padString(input: reservationEndDay))
                
                if reservationStart! <= currentDate! && reservationEnd! >= currentDate! {
                    return false
                }
                
            } else if reservation.getReservationType() == "Monthly" {
                let currentDate = Int(String(calendar.component(.year, from: today)) + "" + String(calendar.component(.month, from: today)) + "" + String(calendar.component(.day, from: today)))
                let reservationStartYear = reservation.getStart().components(separatedBy: "/")[0]
                let reservationStartMonth = reservation.getStart().components(separatedBy: "/")[1]
                let reservationStartDay = reservation.getStart().components(separatedBy: "/")[2]
                let reservationStart = Int(reservationStartYear + reservationStartMonth + reservationStartDay)
                
                if reservationStart! <= currentDate! {
                    return false
                }
            }
        }
        
        return true
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
     @Params: a number in the format of an int
     @Returns: a string with a leading 0 if there was originally only 1 digit
     */
    func padInteger(input: Int) -> String {
        
        if String(input).characters.count < 2 {
            return "0" + String(input)
        }
        
        return String(input)
    }
}
