//
//  ManageCardViewController.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import UIKit

class ManageCardViewController: UIViewController {

    @IBOutlet weak var cardLabel: UILabel!
    @IBOutlet weak var makeDefaultButton: UIButton!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var card:Card!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var ipAddress:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.barTintColor = appDelegate.colorPrimaryDark
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        self.title = "Manage Card"
        
        ipAddress = appDelegate.ipAddress
        
        if card != nil {
            self.cardLabel.text = card.getCardString()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Set selected card as the default card.
    @IBAction func makeDefaultButtonPressed(_ sender: Any) {
        self.activityIndicator.startAnimating()
        self.makeDefaultButton.isEnabled = false
        self.makeDefaultButton.backgroundColor = UIColor.lightGray
        self.deleteButton.isEnabled = false
        self.deleteButton.backgroundColor = UIColor.lightGray
        
        let sessionid = UserDefaults.standard.object(forKey: "sessionid")!
        let token = card.getToken()
        
        let postString = "sessionid=\(sessionid)&token=\(token)"
        
        let myURL = URL(string: "https://" + self.ipAddress + "")
        let request = NSMutableURLRequest(url: myURL!)
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if(data == nil) {
                
                DispatchQueue.main.async(execute: {
                    self.activityIndicator.stopAnimating()
                    self.makeDefaultButton.isEnabled = true
                    self.makeDefaultButton.backgroundColor = self.appDelegate.colorPrimary
                    self.deleteButton.isEnabled = true
                    self.deleteButton.backgroundColor = UIColor.red
                    self.displayAlertMessage("Could not reach server. Please try again.")
                })
                return
            }
            
            do{
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    
                    let status = parseJSON["status"] as? String
                    let message = parseJSON["message"] as? String
                    
                    DispatchQueue.main.async(execute: {
                        
                        // Display alert message with confirmation
                        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.alert)
                        
                        var okAction: UIAlertAction
                        
                        if(status == "Success") {
                            okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {
                                action in
                                
                                self.performSegue(withIdentifier: "unwindToPaymentsViewController", sender: self)
                                
                            })
                        } else {
                            if message == "Please log in." {
                                self.appDelegate.logoutFunction()
                                return
                            }
                            okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
                        }
                        
                        self.activityIndicator.stopAnimating()
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                    })
                    
                }
            } catch _ as NSError {
                DispatchQueue.main.async(execute: {
                    self.activityIndicator.stopAnimating()
                    
                    self.displayAlertMessage("There was an error. Please try again.")
                })
            }
            }.resume()
    }
    
    // Delete user's credit/debit card.
    @IBAction func deleteButtonPressed(_ sender: Any) {
        self.activityIndicator.startAnimating()
        self.makeDefaultButton.isEnabled = false
        self.makeDefaultButton.backgroundColor = UIColor.lightGray
        self.deleteButton.isEnabled = false
        self.deleteButton.backgroundColor = UIColor.lightGray
        
        let sessionid = UserDefaults.standard.object(forKey: "sessionid")!
        let token = card.getToken()
        
        let postString = "sessionid=\(sessionid)&token=\(token)"
        
        let myURL = URL(string: "https://" + self.ipAddress + "")
        let request = NSMutableURLRequest(url: myURL!)
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if(data == nil) {
                
                DispatchQueue.main.async(execute: {
                    self.activityIndicator.stopAnimating()
                    self.makeDefaultButton.isEnabled = true
                    self.makeDefaultButton.backgroundColor = self.appDelegate.colorPrimary
                    self.deleteButton.isEnabled = true
                    self.deleteButton.backgroundColor = UIColor.red
                    self.displayAlertMessage("Could not reach server. Please try again.")
                })
                return
            }
            
            do{
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    
                    let status = parseJSON["status"] as? String
                    let message = parseJSON["message"] as? String
                    
                    DispatchQueue.main.async(execute: {
                        
                        // Display alert message with confirmation
                        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.alert)
                        
                        var okAction: UIAlertAction
                        
                        if(status == "Success") {
                            okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: {
                                action in
                                
                                self.performSegue(withIdentifier: "unwindToPaymentsViewController", sender: self)
                                
                            })
                        } else {
                            if message == "Please log in." {
                                self.appDelegate.logoutFunction()
                                return
                            }
                            okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
                        }
                        
                        self.activityIndicator.stopAnimating()
                        alert.addAction(okAction)
                        self.present(alert, animated: true, completion: nil)
                    })
                    
                }
            } catch _ as NSError {
                DispatchQueue.main.async(execute: {
                    self.activityIndicator.stopAnimating()
                    
                    self.displayAlertMessage("There was an error. Please try again.")
                })
            }
        }.resume()
    }
    
    // Display alert message
    func displayAlertMessage(_ userMessage: String) {
        let alert = UIAlertController(title: "Alert", message: userMessage, preferredStyle: UIAlertControllerStyle.alert)
        
        let okAction = UIAlertAction(title: "Ok", style: UIAlertActionStyle.default, handler: nil)
        
        alert.addAction(okAction)
        
        self.present(alert, animated:true, completion: nil)
    }
}
