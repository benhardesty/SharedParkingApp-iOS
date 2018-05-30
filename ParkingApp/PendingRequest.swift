//
//  PendingRequest.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import Foundation
import UIKit

open class PendingRequest {
    
    fileprivate var requestID:Int!
    fileprivate var spotID:Int!
    fileprivate var spotAddress:String!
    fileprivate var start:String!
    fileprivate var end:String!
    fileprivate var reservationType:String!
    fileprivate var access:String!
    fileprivate var hours:String!
    fileprivate var totalPrice:Double!
    fileprivate var timeStamp:String!
    fileprivate var spotOwnerDetails:String
    fileprivate var renterDetails:String!
    
    init(request: [String : AnyObject]) {
        
        self.requestID = request["requestID"] as! Int
        self.spotID = request["spotID"] as! Int
        self.spotAddress = request["spotAddress"] as! String
        self.start = request["start"] as! String
        self.end = request["end"] as! String
        self.reservationType = request["reservationType"] as! String
        self.access = request["access"] as! String
        self.hours = request["hours"] as! String
        self.totalPrice = request["totalPrice"] as! Double
        self.timeStamp = request["timeStamp"] as! String
        self.spotOwnerDetails = request["spotOwnerDetails"] as! String
        self.renterDetails = request["spotOwnerDetails"] as! String
    }
    
    func getRequestID() -> Int {
        return self.requestID
    }
    func getSpotID() -> Int {
        return self.spotID
    }
    func getSpotAddress() -> String {
        return self.spotAddress
    }
    func getStart() -> String {
        return self.start
    }
    func getEnd() -> String {
        return self.end
    }
    func getReservationType() -> String {
        return self.reservationType
    }
    func getAccess() -> String {
        return self.access
    }
    func getHours() -> String {
        return self.hours
    }
    func getTotalPrice() -> Double {
        return self.totalPrice
    }
    func getTimeStamp() -> String {
        return self.timeStamp
    }
    func getSpotOwnerDetails() -> String {
        return self.spotOwnerDetails
    }
    func getRenterDetails() -> String {
        return self.renterDetails
    }
}
