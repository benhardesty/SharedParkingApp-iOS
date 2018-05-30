//
//  MyRequestsViewController.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import UIKit
import MMDrawerController

class MyRequestsViewController: UITableViewController {

    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var ipAddress:String!
    var requests = [PendingRequest]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = appDelegate.colorPrimaryDark
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        self.title = "My Pending Requests"
        ipAddress = appDelegate.ipAddress
    }
    
    override func viewDidAppear(_ animated: Bool) {
        requests = []
        self.tableView.reloadData()
        loadRequests()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if requests.count == 0 {
            let noDataLabel = UILabel(frame: CGRect(x: 0,y: 0,width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.text = "No Requests"
            noDataLabel.textColor = UIColor.black
            noDataLabel.textAlignment = .center
            tableView.backgroundView = noDataLabel
        } else {
            tableView.backgroundView = nil
        }
        return requests.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Configure the cell.
        let cell = tableView.dequeueReusableCell(withIdentifier: "myRequestCell", for: indexPath) as! PendingRequestCell
        
        let start = requests[indexPath.row].getStart()
        let end = requests[indexPath.row].getEnd()
        var datesText = ""
        
        switch requests[indexPath.row].getReservationType() {
        case "Monthly":
            if end == "none" {
                let startText = start.components(separatedBy: "/")
                datesText = "Starting: \(startText[1])/\(startText[2])/\(startText[0])"
            } else {
                let startText = start.components(separatedBy: "/")
                let endText = end.components(separatedBy: "/")
                datesText = "\(startText[1])/\(startText[2])/\(startText[0]) - \(endText[1])/\(endText[2])/\(endText[0])"
            }
            break
        case "Daily":
            let startText = start.components(separatedBy: "/")
            let endText = end.components(separatedBy: "/")
            datesText = "Requested Dates: \(startText[1])/\(startText[2])/\(startText[0]) - \(endText[1])/\(endText[2])/\(endText[0])"
            break
        case "Hourly":
            let startText = start.components(separatedBy: "/")
            let endText = end.components(separatedBy: "/")
            
            let startTime = convert24to12(time: startText[3] + ":" + startText[4])
            let endTime = convert24to12(time: endText[3] + ":" + endText[4])
            
            datesText = "\(startText[1])/\(startText[2])/\(startText[0]): \(startTime) - \(endTime)"
            break
        default:
            break
        }
        
        cell.spotAddressLabel.text = requests[indexPath.row].getSpotAddress()
        cell.detailsLabel.text = datesText
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any!) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        let nav = segue.destination as! UINavigationController
        let destViewController = nav.topViewController as! CancelMyRequestViewController
        
        if let cell = sender as? UITableViewCell {
            let i = tableView.indexPath(for: cell)!.row
            destViewController.request = requests[i]
        }
    }
    
    
    @IBAction func unwindCancelToMyRequestsViewController(_ unwindSegue: UIStoryboardSegue){
    }
    
    
    // Open the Navigation Drawer when hamburger button is tapped.
    @IBAction func leftSideButtonTapped(_ sender: AnyObject) {
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.centerContainer!.toggle(MMDrawerSide.left, animated: true, completion: nil)
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
    
    // Pull user's pending reservation requests from the server.
    func loadRequests() {
        
        let sessionid = UserDefaults.standard.object(forKey: "sessionid")!
        
        let myURL = URL(string: "https://" + ipAddress + "")
        let postString = "sessionid=\(String(describing: sessionid))"
        let request = NSMutableURLRequest(url: myURL!)
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {data, response, error in
            
            if(data == nil) {
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
                        let requests = parseJSON["data"] as! [[String : AnyObject]]
                        for request in requests {
                            let newRequest: PendingRequest = PendingRequest(request: request)
                            self.requests.append(newRequest)
                        }
                    } else {
                        let message = parseJSON["message"] as? String
                        if message == "Please log in." {
                            DispatchQueue.main.async(execute: {
                                self.appDelegate.logoutFunction()
                                return
                            })
                        }
                    }
                    
                    DispatchQueue.main.async(execute: {
                        self.tableView.reloadData()
                    })
                }
            } catch _ as NSError {
            }
        }
        task.resume()
    }
    
    // Display alert message.
    func displayAlertMessage(_ userMessage: String) {
        let alert = UIAlertController(title: "Alert", message: userMessage, preferredStyle: UIAlertControllerStyle.alert)
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
        alert.addAction(okAction)
        self.present(alert, animated:true, completion: nil)
    }
}
