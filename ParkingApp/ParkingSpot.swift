//
//  ParkingSpot.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import Foundation
import GoogleMaps

class ParkingSpot: Spot {
    
    var active: Int!
    var spotType:String!
    var accessType:String!
    var availableMonthly:Int!
    var monthlyPrice:Double!
    var monthlyHours:String!
    var availableDaily:Int!
    var dailyPrice:Double!
    var dailyHours:String!
    var availableHourly:Int!
    var hourlyPrice:Double!
    var hourlyHours:String!
    var spotNumber:String!
    var spotRating:String!
    var Marker: GMSMarker?
    
    override init(spot: [String : AnyObject]) {
        super.init(spot: spot)
        
        self.active = spot["active"] as! Int
        self.spotType = spot["spotType"] as! String
        self.accessType = spot["accessType"] as! String
        self.availableMonthly = spot["availableMonthly"] as! Int
        self.monthlyPrice = spot["monthlyPrice"] as! Double
        self.monthlyHours = spot["monthlyHours"] as! String
        self.availableDaily = spot["availableDaily"] as! Int
        self.dailyPrice = spot["dailyPrice"] as! Double
        self.dailyHours = spot["dailyHours"] as! String
        self.availableHourly = spot["availableHourly"] as! Int
        self.hourlyPrice = spot["hourlyPrice"] as! Double
        self.hourlyHours = spot["hourlyHours"] as! String
        self.spotNumber = spot["spotNumber"] as! String
        self.spotRating = "No ratings."
    }
    
    func getActive() -> Int {
        return self.active
    }
    func getSpotType() -> String {
        return self.spotType
    }
    func getAccessType() -> String {
        return self.accessType
    }
    func getAvailableMonthly() -> Int {
        return self.availableMonthly
    }
    func getMonthlyPrice() -> Double {
        return self.monthlyPrice
    }
    func getMonthlyHours() -> String {
        return self.monthlyHours
    }
    func getAvailableDaily() -> Int {
        return self.availableDaily
    }
    func getDailyPrice() -> Double {
        return self.dailyPrice
    }
    func getDailyHours() -> String {
        return self.dailyHours
    }
    func getAvailableHourly() -> Int {
        return self.availableHourly
    }
    func getHourlyPrice() -> Double {
        return self.hourlyPrice
    }
    func getHourlyHours() -> String {
        return self.hourlyHours
    }
    func getSpotNumber() -> String {
        return self.spotNumber
    }
    
    func getSpotRating() -> String {
        return self.spotRating
    }
}
