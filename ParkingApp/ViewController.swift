//
//  ViewController.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import UIKit
import GoogleMaps
import MMDrawerController

class ViewController: UIViewController, GMSMapViewDelegate {

    // MARK: Properties
    @IBOutlet var mapView: GMSMapView!
    
    @IBAction func unwindToViewControllerViewController(_ unwindSegue: UIStoryboardSegue){
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Open the Navigation Drawer when hamburger button is tapped.
    @IBAction func leftSideButtonTapped(_ sender: AnyObject) {
        let appDelegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.centerContainer!.toggle(MMDrawerSide.left, animated: true, completion: nil)
    }
}
