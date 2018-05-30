//
//  PaymentsViewController.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import UIKit
import MMDrawerController
import Braintree
import BraintreeDropIn

class PaymentsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: Outlets
    @IBOutlet weak var addCardButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    // MARK: Global Variables
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var ipAddress:String!
    var clientToken:String = ""
    var dataCollector: BTDataCollector!
    var cards = [Card]()
    var rowSelected:Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.contentSize.height = 480
        self.navigationController?.navigationBar.barTintColor = appDelegate.colorPrimaryDark
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        self.title = "Payments"
        ipAddress = appDelegate.ipAddress
        
        addCardButton.isHidden = true
        tableView.isHidden = true
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(PendingRequestCell.self, forCellReuseIdentifier: "CardCell")
        tableView.layer.borderWidth = 1
        tableView.layer.borderColor = UIColor.gray.cgColor
        tableView.layer.cornerRadius = 5
        tableView.backgroundColor = UIColor.lightGray
        
        fetchClientToken()
        refreshCards()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cards.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell:UITableViewCell = tableView.dequeueReusableCell(withIdentifier: "CardCell", for: indexPath)
        cell.textLabel!.text = cards[indexPath.row].getCardString()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.rowSelected = indexPath.row
        self.performSegue(withIdentifier: "manageCard", sender: self)
    }
    
    // Add a payment card to user's "wallet".
    @IBAction func addCardButtonClicked(_ sender: Any) {
        addCardButton.isEnabled = false
        self.addCardButton.backgroundColor = UIColor.lightGray
        self.activityIndicator.startAnimating()
        showDropIn(clientTokenOrTokenizationKey: self.clientToken)
    }
    
    // Fetch client token.
    func fetchClientToken() {
        self.activityIndicator.startAnimating()
        let myURL = URL(string: "https://" + ipAddress + "")
        let sessionid = UserDefaults.standard.object(forKey: "sessionid")!
        let postString = "sessionid=\(sessionid)"
        let request = NSMutableURLRequest(url: myURL!)
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if(data == nil) {
                DispatchQueue.main.async(execute: {
                    self.activityIndicator.stopAnimating()
                    self.displayAlertMessage("Could not reach server. Please try again.")
                })
                return
            }
            
            self.clientToken = String(data: data!, encoding: String.Encoding.utf8)!
            
            if let apiClient = BTAPIClient(authorization: self.clientToken) {
                self.dataCollector = BTDataCollector(apiClient: apiClient)
            }
            
            DispatchQueue.main.async(execute: {
                self.activityIndicator.stopAnimating()
                self.addCardButton.isHidden = false
                self.tableView.isHidden = false
            })
        }.resume()
    }
    
    // Show braintree dropin for adding a credit/debit card.
    func showDropIn(clientTokenOrTokenizationKey: String) {
        let request = BTDropInRequest()
        let dropIn = BTDropInController(authorization: clientTokenOrTokenizationKey, request: request)
        {
            (controller, result, error) in
            if (error != nil) {
                self.activityIndicator.stopAnimating()
                self.addCardButton.backgroundColor = self.appDelegate.colorAccent
                self.addCardButton.isEnabled = true
            } else if (result?.isCancelled == true) {
                self.activityIndicator.stopAnimating()
                self.addCardButton.backgroundColor = self.appDelegate.colorAccent
                self.addCardButton.isEnabled = true
            } else if let result = result {
                self.postNonceToServer(paymentMethodNonce: result.paymentMethod!.nonce)
            }
            controller.dismiss(animated: true, completion: nil)
        }
        self.present(dropIn!, animated: true, completion: nil)
    }
    
    // Send new payment method to server for validation.
    func postNonceToServer(paymentMethodNonce: String) {
        
        self.dataCollector.collectFraudData() {
            deviceData in
            
            let sessionid = UserDefaults.standard.object(forKey: "sessionid")!
            let postString = "sessionid=\(sessionid)&payment_method_nonce=\(paymentMethodNonce)&deviceData=\(deviceData)"
            let myURL = URL(string: "https://" + self.ipAddress + "")
            let request = NSMutableURLRequest(url: myURL!)
            request.httpMethod = "POST"
            request.httpBody = postString.data(using: String.Encoding.utf8)
            
            URLSession.shared.dataTask(with: request as URLRequest) {
                data, response, error in
                
                if(data == nil) {
                    DispatchQueue.main.async(execute: {
                        self.activityIndicator.stopAnimating()
                        self.addCardButton.isEnabled = true
                        self.addCardButton.backgroundColor = self.appDelegate.colorAccent
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
                            if(status == "Success") {
                                self.activityIndicator.stopAnimating()
                                self.addCardButton.isEnabled = true
                                self.addCardButton.backgroundColor = self.appDelegate.colorAccent
                                self.cards.removeAll()
                                self.tableView.reloadData()
                                self.refreshCards()
                                self.displayAlertMessage(message!)
                            } else {
                                if message == "Please log in." {
                                    self.appDelegate.logoutFunction()
                                    self.displayAlertMessage(message!)
                                    return
                                } else {
                                    self.activityIndicator.stopAnimating()
                                    self.addCardButton.isEnabled = true
                                    self.addCardButton.backgroundColor = self.appDelegate.colorAccent
                                    self.displayAlertMessage(message!)
                                }
                            }
                        })
                    }
                } catch _ as NSError {
                    DispatchQueue.main.async(execute: {
                        self.activityIndicator.stopAnimating()
                        self.addCardButton.isEnabled = true
                        self.addCardButton.backgroundColor = self.appDelegate.colorAccent
                        self.displayAlertMessage("There was an error. Please try again.")
                    })
                }
            }.resume()
        }
    }
    
    // Refresh cards list view once server has processed the request to add a payment method.
    func refreshCards() {
        
        self.activityIndicator.startAnimating()
        let sessionid = UserDefaults.standard.object(forKey: "sessionid")!
        let postString = "sessionid=\(sessionid)"
        let myURL = URL(string: "https://" + self.ipAddress + "")
        let request = NSMutableURLRequest(url: myURL!)
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if(data == nil) {
                DispatchQueue.main.async(execute: {
                    self.activityIndicator.stopAnimating()
                    self.displayAlertMessage("Could not reach server. Please try again.")
                })
                return
            }
            
            do{
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary
                
                if let parseJSON = json {
                    
                    let status = parseJSON["status"] as? String
                    
                    if status == "Success" {
                        let cards = parseJSON["creditCards"] as! [[String : AnyObject]]
                        
                        for card in cards {
                            let card = Card(card: card)
                            self.cards.append(card)
                        }
                        
                        DispatchQueue.main.async(execute: {
                            self.activityIndicator.stopAnimating()
                            self.tableView.isHidden = false
                            self.tableView.reloadData()
                        })
                    }
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
    
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "manageCard" {
            let nav = segue.destination as! UINavigationController
            let destViewController = nav.topViewController as! ManageCardViewController
            destViewController.card = self.cards[self.rowSelected]
        }
    }
    
    @IBAction func unwindToPaymentsViewController(_ unwindSegue: UIStoryboardSegue){
        cards.removeAll()
        self.tableView.reloadData()
        self.refreshCards()
    }
    
    // Open the Navigation Drawer when hamburger button is tapped.
    @IBAction func leftSideButtonTapped(_ sender: AnyObject) {
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.centerContainer!.toggle(MMDrawerSide.left, animated: true, completion: nil)
    }
}
