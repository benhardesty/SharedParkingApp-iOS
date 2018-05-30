//
//  GoogleMap.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces
import GooglePlacePicker
import CoreLocation
import Foundation
import TTRangeSlider

class GoogleMap: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate {
    
    // MARK: Google Places API Variables
    var resultsViewController: GMSAutocompleteResultsViewController?
    var searchController: UISearchController?
    var resultView: UITextView?
    var filterType: String = "All"
    var markerImageView: UIImageView?
    var markerUnavailableImageView: UIImageView?
    
    // MARK: Outlets
    @IBOutlet var googleMapView: UIView!
    
    // MARK: Global Variables
    var mapView: GMSMapView!
    var spotsArray = [ParkingSpot]()
    var newSpots = [ParkingSpot]()
    var spotsToAdd = [ParkingSpot]()
    var mapWidth: CGFloat!
    var mapHeight: CGFloat!
    let heightAdjustment: CGFloat = 0
    let positionAdjustmentX: CGFloat = 0
    var allSpotsFilterButton:UIButton!
    var monthlyFilterButton:UIButton!
    var dailyFilterButton:UIButton!
    var hourlyFilterButton:UIButton!
    var priceLabel:UILabel!
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    var ipAddress:String!
    
    // Initialize Location Manager.
    let locationManager = CLLocationManager()
    
    // Track marker clicked to be used in prepareForSegue
    var currentMarker:String!
    
    // Filter spots by price
    var minPrice = 0.00
    var maxPrice = 750.00
    var sliderIsSet = false
    var rangeSlider:TTRangeSlider!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize global variables
        mapWidth = googleMapView.bounds.size.width
        mapHeight = googleMapView.bounds.size.height
        
        let markerView = UIImage(named: "map_marker")
        markerImageView = UIImageView(image: markerView)
        
        let markerUnavailableView = UIImage(named: "map_marker_unavailable")
        markerUnavailableImageView = UIImageView(image: markerUnavailableView)
        
        // Local variables used to initialize camera position on mapView
        var camera: GMSCameraPosition
        var location: CLLocationCoordinate2D
        
        // If the location manager has the phone's last location, initialize map to phone's location.
        if locationManager.location != nil {
            
            // Initialize map to phone's last location
            location = locationManager.location!.coordinate
            camera = GMSCameraPosition.camera(withTarget: location, zoom: 10)
            mapView = GMSMapView.map(withFrame: CGRect(x: 0, y: heightAdjustment, width: mapWidth, height: mapHeight - heightAdjustment), camera: camera)
            mapView.delegate = self
            self.view.addSubview(mapView)
            
        } else { // Otherwise initialize map's location over San Francisco.
            
            // Initialize map over San Francisco
            location = CLLocationCoordinate2DMake(37.78, -122.44)
            camera = GMSCameraPosition.camera(withTarget: location, zoom: 10)
            mapView = GMSMapView.map(withFrame: CGRect(x: 0, y: heightAdjustment, width: mapWidth, height: mapHeight - heightAdjustment), camera: camera)
            mapView.delegate = self
            self.view.addSubview(mapView)
        }
        
        let lightBlue = UIColor.init(red: 51/255, green: 153/255, blue: 255/255, alpha: 1.0)
        let darkBlue = UIColor.init(red: 0/255, green: 89/255, blue: 179/255, alpha: 1.0)
        
        // Initialize buttons, labels, and price slider bar
        priceLabel = UILabel(frame: CGRect(x: 10, y: mapHeight - 150, width: 80, height: 20))
        priceLabel.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        priceLabel.layer.cornerRadius = 5
        priceLabel.layer.masksToBounds = true
        priceLabel.textColor = appDelegate.colorAccent
        priceLabel.adjustsFontSizeToFitWidth = true
        mapView.addSubview(priceLabel)
        
        allSpotsFilterButton = UIButton(frame: CGRect(x: 10, y: mapHeight - 125, width: 80, height: 20))
        allSpotsFilterButton.backgroundColor = darkBlue.withAlphaComponent(0.7)
        allSpotsFilterButton.setTitle("All Spots", for: UIControlState())
        allSpotsFilterButton.setTitleColor(UIColor.white, for: UIControlState())
        allSpotsFilterButton.layer.cornerRadius = 5;
        mapView.addSubview(allSpotsFilterButton)
        
        monthlyFilterButton = UIButton(frame: CGRect(x: 10, y: mapHeight - 100, width: 80, height: 20))
        monthlyFilterButton.backgroundColor = lightBlue.withAlphaComponent(0.7)
        monthlyFilterButton.setTitle("Monthly", for: UIControlState())
        monthlyFilterButton.setTitleColor(UIColor.white, for: UIControlState())
        monthlyFilterButton.layer.cornerRadius = 5;
        mapView.addSubview(monthlyFilterButton)
        
        dailyFilterButton = UIButton(frame: CGRect(x: 10, y: mapHeight - 75, width: 80, height: 20))
        dailyFilterButton.backgroundColor = lightBlue.withAlphaComponent(0.7)
        dailyFilterButton.setTitle("Daily", for: UIControlState())
        dailyFilterButton.setTitleColor(UIColor.white, for: UIControlState())
        dailyFilterButton.layer.cornerRadius = 5;
        mapView.addSubview(dailyFilterButton)
        
        hourlyFilterButton = UIButton(frame: CGRect(x: 10, y: mapHeight - 50, width: 80, height: 20))
        hourlyFilterButton.backgroundColor = lightBlue.withAlphaComponent(0.7)
        hourlyFilterButton.setTitle("Hourly", for: UIControlState())
        hourlyFilterButton.setTitleColor(UIColor.white, for: UIControlState())
        hourlyFilterButton.layer.cornerRadius = 5;
        mapView.addSubview(hourlyFilterButton)
        
        allSpotsFilterButton.addTarget(self, action: #selector(GoogleMap.filterSpots(_:)), for: UIControlEvents.touchUpInside)
        monthlyFilterButton.addTarget(self, action: #selector(GoogleMap.filterSpots(_:)), for: UIControlEvents.touchUpInside)
        dailyFilterButton.addTarget(self, action: #selector(GoogleMap.filterSpots(_:)), for: UIControlEvents.touchUpInside)
        hourlyFilterButton.addTarget(self, action: #selector(GoogleMap.filterSpots(_:)), for: UIControlEvents.touchUpInside)
        
        // Enable my location button
        mapView.settings.myLocationButton = true
        mapView.isMyLocationEnabled = true
        
        // Enable compass button
        mapView.settings.compassButton = true
        
        // Initialize price slider bar
        rangeSlider = TTRangeSlider()
        rangeSlider.frame = CGRect(x: 0, y: 0, width: 200, height: 50)
        rangeSlider.tintColorBetweenHandles = appDelegate.colorAccent
        rangeSlider.tintColor = UIColor.lightGray
        rangeSlider.handleColor = UIColor.white
        rangeSlider.handleDiameter = 24
        rangeSlider.lineHeight = 3
        rangeSlider.selectedHandleDiameterMultiplier = 1
        rangeSlider.hideLabels = true
        rangeSlider.minValue = Float(self.minPrice)
        rangeSlider.maxValue = Float(self.maxPrice)
        rangeSlider.selectedMinimum = Float(self.minPrice)
        rangeSlider.selectedMaximum = Float(self.maxPrice)
        rangeSlider.addTarget(self, action: #selector(GoogleMap.updatePriceLabel(_:)), for: UIControlEvents.allTouchEvents)
        rangeSlider.addTarget(self, action: #selector(GoogleMap.updateMarkersWithNewPrices(_:)), for: UIControlEvents.touchUpInside)
        let sliderView = UIView(frame: CGRect(x: -75, y: view.frame.height - 275, width: 200, height: 50))
        sliderView.alpha = 0.8
        sliderView.addSubview(rangeSlider)
        sliderView.transform = CGAffineTransform(rotationAngle: CGFloat(-Double.pi / 2))
        
        mapView.addSubview(sliderView)
    }
    
    // MARK: Initialization of map and callback.
    override func viewDidAppear(_ animated: Bool) {
        
        self.navigationController?.navigationBar.barTintColor = appDelegate.colorPrimaryDark
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName : UIColor.white]
        
        ipAddress = appDelegate.ipAddress
        
        // Initialize Location Manager settings
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
        // MARK: Google Places API Initialization
        
        // MARK: Add a search bar to the navigation bar
        resultsViewController = GMSAutocompleteResultsViewController()
        resultsViewController?.delegate = self
        searchController = UISearchController(searchResultsController: resultsViewController)
        searchController?.searchResultsUpdater = resultsViewController
        
        // Put the search bar in the navigation bar.
        searchController?.searchBar.sizeToFit()
        self.navigationController?.navigationBar.topItem?.titleView = searchController?.searchBar
        
        // When UISearchController presents the results view, present it in
        // this view controller, not one further up the chain.
        self.definesPresentationContext = true
        
        // Prevent the navigation bar from being hidden when searching.
        searchController?.hidesNavigationBarDuringPresentation = false
        
        // Update price label.
        updatePriceLabel(priceLabel)
        
        // Load markers onto map
        loadMarkers()
    }
    
    // Change filter for Monthly, Daily, or Hourly.
    func filterSpots(_ sender: UIButton) {
        let lightBlue = UIColor.init(red: 51/255, green: 153/255, blue: 255/255, alpha: 1.0)
        let darkBlue = UIColor.init(red: 0/255, green: 89/255, blue: 179/255, alpha: 1.0)
        
        if sender == allSpotsFilterButton {
            filterType = "All"
            rangeSlider.maxValue = 750.00
            allSpotsFilterButton.backgroundColor = darkBlue.withAlphaComponent(0.7)
            monthlyFilterButton.backgroundColor = lightBlue.withAlphaComponent(0.7)
            dailyFilterButton.backgroundColor = lightBlue.withAlphaComponent(0.7)
            hourlyFilterButton.backgroundColor = lightBlue.withAlphaComponent(0.7)
        } else if sender == monthlyFilterButton {
            filterType = "Monthly"
            rangeSlider.maxValue = 750.00
            allSpotsFilterButton.backgroundColor = lightBlue.withAlphaComponent(0.7)
            monthlyFilterButton.backgroundColor = darkBlue.withAlphaComponent(0.7)
            dailyFilterButton.backgroundColor = lightBlue.withAlphaComponent(0.7)
            hourlyFilterButton.backgroundColor = lightBlue.withAlphaComponent(0.7)
        } else if sender == dailyFilterButton {
            filterType = "Daily"
            
            self.maxPrice = 150.00
            rangeSlider.maxValue = 150.00
            if rangeSlider.selectedMaximum > 150.00 {
                rangeSlider.selectedMaximum = 150.00
            }
            self.updatePriceLabel(priceLabel)
            
            allSpotsFilterButton.backgroundColor = lightBlue.withAlphaComponent(0.7)
            monthlyFilterButton.backgroundColor = lightBlue.withAlphaComponent(0.7)
            dailyFilterButton.backgroundColor = darkBlue.withAlphaComponent(0.7)
            hourlyFilterButton.backgroundColor = lightBlue.withAlphaComponent(0.7)
        } else if sender == hourlyFilterButton {
            filterType = "Hourly"
            
            self.maxPrice = 75.00
            rangeSlider.maxValue = 75.00
            if rangeSlider.selectedMaximum > 75.00 {
                rangeSlider.selectedMaximum = 75.00
            }
            self.updatePriceLabel(priceLabel)
            
            allSpotsFilterButton.backgroundColor = lightBlue.withAlphaComponent(0.7)
            monthlyFilterButton.backgroundColor = lightBlue.withAlphaComponent(0.7)
            dailyFilterButton.backgroundColor = lightBlue.withAlphaComponent(0.7)
            hourlyFilterButton.backgroundColor = darkBlue.withAlphaComponent(0.7)
        }
        
        // Pull new data with the updated filter type.
        loadMarkers()
    }
    
    // Show spot details when marker is clicked.
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        currentMarker = marker.title
        performSegue(withIdentifier: "reserveSpotSegue", sender: nil)
        return true
    }
    
    // Load spots when map tiles finish loading
    func mapViewDidFinishTileRendering(_ mapView: GMSMapView) {
        loadMarkers()
    }
    
    // Return location data of user
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location = locations.last
        let eventDate = location?.timestamp
        _ = eventDate?.timeIntervalSinceNow
    }
    
    // Update price label
    func updatePriceLabel(_ sender: Any) {
        let lower = String(format: "%.0f", rangeSlider.selectedMinimum)
        let upper = String(format: "%.0f", rangeSlider.selectedMaximum)
        priceLabel.text = "$\(lower) - $\(upper)"
    }
    
    // Pull new data with the updated prices
    func updateMarkersWithNewPrices(_ sender: Any) {
        self.minPrice = Double(rangeSlider.selectedMinimum)
        self.maxPrice = Double(rangeSlider.selectedMaximum)
        loadMarkers()
    }
    
    // MARK: Load Markers
    
    // Load markers from database to map.
    func loadMarkers() {
        
        // Get map bounds.
        let swbounds = mapView.projection.visibleRegion().nearLeft
        let swlat = swbounds.latitude
        let nebounds = mapView.projection.visibleRegion().farRight
        let nelat = nebounds.latitude
        
        let myURL = URL(string: "https://" + ipAddress + "")
        let postString = "nelat=\(nelat)&swlat=\(swlat)&filterType=\(filterType)&max=\(maxPrice)&min=\(minPrice)"
        let request = NSMutableURLRequest(url: myURL!)
        request.httpMethod = "POST"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {
            data, response, error in
            
            if(data == nil) {
                return
            }
            
            do{
                let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as? NSDictionary
                
                if let parseJSON = json {
                    
                    let resultValue = parseJSON["status"] as? String
                    
                    if(resultValue == "Success") {
                        let spotsData = parseJSON["data"] as! [[String : AnyObject]]
                        
                        var indexToAddToMap = [Int]()
                        var indexOfNewSpotsInSpotsArray = [Int]()
                        
                        // Go through spots data returned by server
                        for spotData in spotsData {
                            let spot = ParkingSpot(spot: spotData)
                            
                            if self.spotsArray.contains(spot) {
                                // If spotsArray already contains spot,
                                // add the spot's index in the spotsArray to the
                                // indexOfNewSpotsInSpotsArray array
                                indexOfNewSpotsInSpotsArray.append(self.spotsArray.index(of: spot)!)
                            } else {
                                
                                // If spotsArray doens't contain spot, add the spot to the spotsArray
                                // and add the index of the newly added spot in the spotsArray to the
                                // indexToAddToMap array
                                self.spotsArray.append(spot)
                                let index = self.spotsArray.index(of: spot)
                                indexToAddToMap.append(index!)
                                
                                // Add spot to the newSpots aray. This will be used to determine spots
                                // that are currently in the spotsArray but are no longer visible on
                                // the map.
                                // Add the spot's index in the spotsArray to the
                                // indexOfNewSpotsInSpotsArray array
                                indexOfNewSpotsInSpotsArray.append(index!)
                            }
                        }
                        
                        DispatchQueue.main.async(execute: {
                            
                            // Go through the spotsArray for each index included in the indexToAddToMap
                            // array and set the Marker for the spot
                            for index in indexToAddToMap {
                                self.spotsArray[index].Marker = GMSMarker()
                                self.spotsArray[index].Marker!.iconView = self.markerImageView!
                                self.spotsArray[index].Marker!.position = CLLocationCoordinate2DMake(self.spotsArray[index].getSpotLatitude(), self.spotsArray[index].getSpotLongitude())
                                self.spotsArray[index].Marker!.title = String(self.spotsArray[index].getSpotID())
                                self.spotsArray[index].Marker?.map = self.mapView
                            }
                            
                            var indexAdjustment = 0
                            
                            // Go through the spotsArray
                            for spot in self.spotsArray {
                                
                                // Get the index of the spot in the spotsArray
                                let index = self.spotsArray.index(of: spot)!
                                
                                // If the index of the spot in the spotsArray is one of the indexes
                                // that was added to the IndexOfNewSpotsInSpotsArray, then it was one
                                // of the spots returned by the server - do nothing
                                if indexOfNewSpotsInSpotsArray.contains(index + indexAdjustment) {
                                    
                                } else {
                                    // Otherwise, remove the spot
                                    self.removeMarker(index)
                                    indexAdjustment += 1
                                }
                            }
                            
                            indexToAddToMap.removeAll()
                            indexOfNewSpotsInSpotsArray.removeAll()
                            
                        })
                    } else {
                        DispatchQueue.main.async(execute: {
                            
                            for spot in self.spotsArray {
                                let index = self.spotsArray.index(of: spot)
                                self.removeMarker(index!)
                            }
                        })
                    }
                    
                }
            } catch _ as NSError {
            }
            
        }
        task.resume()
    }
    
    /*
     @Params: Number in the format of a string
     @Returns: String with a leading 0 if there was originally only 1 character
     */
    func padString(input: String) -> String {
        
        if input.characters.count < 2 {
            return "0" + input
        }
        
        return input
    }
    
    // Remove all markers from map and delete from spotsArray.
    func removeMarkers(_ localArray: inout [ParkingSpot]) {
        for parkingSpot in localArray {
            parkingSpot.Marker?.map = nil
            parkingSpot.Marker = nil
        }
        localArray.removeAll()
    }
    
    // Remove a specific marker from the map and delete it from spotsArray.
    func removeMarker(_ index: Int) {
        self.spotsArray[index].Marker?.map = nil
        self.spotsArray[index].Marker = nil
        self.spotsArray.remove(at: index)
    }
    
    
    // Update camera location.
    func updateCamera(_ location: CLLocationCoordinate2D) {
        mapView.animate(toLocation: location)
        mapView.animate(toZoom: 16.5)
    }
    
    // MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let nav = segue.destination as! UINavigationController
        let reserveSpotViewController = nav.topViewController as! ReserveSpotViewController
        
        reserveSpotViewController.spotID = currentMarker
        reserveSpotViewController.filterType = filterType
    }
}


// MARK: Google Places API functions

// MARK: Add a search bar to the navigation bar

// Handle the user's selection.
extension GoogleMap: GMSAutocompleteResultsViewControllerDelegate {
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didAutocompleteWith place: GMSPlace) {
        searchController?.isActive = false
        // Do something with the selected place.
        updateCamera(place.coordinate)
    }
    
    func resultsController(_ resultsController: GMSAutocompleteResultsViewController,
                           didFailAutocompleteWithError error: Error){
        // TODO: handle the error.
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(forResultsController resultsController: GMSAutocompleteResultsViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(forResultsController resultsController: GMSAutocompleteResultsViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}
