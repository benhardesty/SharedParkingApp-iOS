//
//  Spot.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import GoogleMaps

class Spot: Equatable {
    var spotID:Int!
    var photos:String!
    var spotAddress:String!
    var spotLatitude:Double!
    var spotLongitude:Double!
    
    init(spot: [String : AnyObject]) {
        
        self.spotID = spot["spotID"] as! Int
        self.photos = spot["photos"] as! String
        self.spotAddress = spot["spotAddress"] as! String
        self.spotLatitude = spot["spotLatitude"] as! Double
        self.spotLongitude = spot["spotLongitude"] as! Double
    }
    
    func getSpotID() -> Int {
        return self.spotID
    }
    func getPhotos() -> String {
        return self.photos
    }
    func getSpotAddress() -> String {
        return self.spotAddress
    }
    func getSpotLatitude() -> Double {
        return self.spotLatitude
    }
    func getSpotLongitude() -> Double {
        return self.spotLongitude
    }
}

func ==(lhs: Spot, rhs: Spot) -> Bool {
    return lhs.spotID == rhs.spotID
}
