//
//  LeftSideViewController.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import UIKit
import MMDrawerController

class LeftSideViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet var tableView: UITableView!
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    var menuItems = [["Find Parking", "My Reservations", "My Pending Requests", "Payments", "Transaction History"], ["My Listed Spots", "List A Spot", "Requests Pending My Response", "Get Paid", "Transaction History"], ["Account", "Logout"]]
    var headerTitles = ["Renters", "Owners", "Account"]
    var images = [[#imageLiteral(resourceName: "Park"), #imageLiteral(resourceName: "MyReservations"), #imageLiteral(resourceName: "MyPendingRequests"), #imageLiteral(resourceName: "Payments"), #imageLiteral(resourceName: "Transactions")],[#imageLiteral(resourceName: "MyListedSpots"), #imageLiteral(resourceName: "ListASpot"), #imageLiteral(resourceName: "RequestsRequiringResponse"), #imageLiteral(resourceName: "Payments"), #imageLiteral(resourceName: "Transactions")],[#imageLiteral(resourceName: "Account"), #imageLiteral(resourceName: "Logout")]]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.barTintColor = appDelegate.colorPrimaryDark
        self.navigationItem.title = "ParkingApp"
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let mycell = tableView.dequeueReusableCell(withIdentifier: "MyCell", for: indexPath) as! MyCustomTableViewCell
        mycell.menuItemLabel.text = menuItems[indexPath.section][indexPath.row]
        mycell.menuIconImageView.image = images[indexPath.section][indexPath.row]
        
        return mycell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section < headerTitles.count {
            return headerTitles[section]
        }
        
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0,y: 0, width: tableView.frame.size.width, height: 18))
        let label = UILabel(frame: CGRect(x: 3, y: 5, width: tableView.frame.size.width, height: 18))
        label.textColor = UIColor.black
        label.font = UIFont.boldSystemFont(ofSize: 16.0)
        label.text = headerTitles[section]
        
        view.addSubview(label)
        return view
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                
                let centerViewController = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as! ViewController
                
                let centerNavController = UINavigationController(rootViewController: centerViewController)
                
                let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
                
                appDelegate.centerContainer!.centerViewController = centerNavController
                appDelegate.centerContainer!.toggle(MMDrawerSide.left, animated: true, completion: nil)
                
                break
                
            case 1:
                
                let myReservations = self.storyboard?.instantiateViewController(withIdentifier: "MyReservationsViewController") as! MyReservationsViewController
                
                let myReservationsNavController = UINavigationController(rootViewController: myReservations)
                
                let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
                
                appDelegate.centerContainer!.centerViewController = myReservationsNavController
                appDelegate.centerContainer!.toggle(MMDrawerSide.left, animated: true, completion: nil)
                
                break
                
            case 2:
                
                let myRequests = self.storyboard?.instantiateViewController(withIdentifier: "MyRequestsViewController") as! MyRequestsViewController
                
                let myRequestsNavController = UINavigationController(rootViewController: myRequests)
                
                let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
                
                appDelegate.centerContainer!.centerViewController = myRequestsNavController
                appDelegate.centerContainer!.toggle(MMDrawerSide.left, animated: true, completion: nil)
                
                break
                
            case 3:
                
                let myPayments = self.storyboard?.instantiateViewController(withIdentifier: "PaymentsViewController") as! PaymentsViewController
                
                let myPaymentsNavController = UINavigationController(rootViewController: myPayments)
                
                let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
                
                appDelegate.centerContainer!.centerViewController = myPaymentsNavController
                appDelegate.centerContainer!.toggle(MMDrawerSide.left, animated: true, completion: nil)
                
                break
                
            case 4:
                // Not posted to GitHub.
                break
                
            default:
                
                break
                
            }
        } else if indexPath.section == 1 {
            switch indexPath.row {
            case 0:
                // Not posted to GitHub.
                break
                
            case 1:
                // Not posted to GitHub.
                break
                
            case 2:
                // Not posted to GitHub.
                break
                
            case 3:
                // Not posted to GitHub.
                break
                
            case 4:
                // Not posted to GitHub.
                break
                
            default:
                
                break
                
            }
        } else if indexPath.section == 2 {
            switch indexPath.row {
            case 0:
                // Not posted to GitHub.
                break
                
            case 1:
                
                let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.logoutFunction()
                
                break
                
            default:
                
                break
                
            }
        }
    }

}
