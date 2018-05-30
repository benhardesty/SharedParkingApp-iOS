//
//  Reservation.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import Foundation

class Reservation {
    
    fileprivate var reservationID:Int!
    fileprivate var spotID:Int!
    fileprivate var spotAddress:String!
    fileprivate var renterName:String!
    fileprivate var renterVehicle:String!
    fileprivate var start:String!
    fileprivate var end:String!
    fileprivate var reservationType:String!
    fileprivate var access:String!
    fileprivate var hours:String!
    fileprivate var totalPrice:Double!
    fileprivate var timeStamp:String!
    fileprivate var reservationCancelledByRentor:Int!
    fileprivate var reservationCancelledByOwner:Int!
    fileprivate var cancelledTimeStamp:String!
    fileprivate var spotOwnerDetails:String!
    
    init(reservation: [String : AnyObject]) {
        
        self.reservationID = reservation["reservationID"] as! Int
        self.spotID = reservation["spotID"] as! Int
        self.spotAddress = reservation["spotAddress"] as! String
        self.renterName = reservation["requestorName"] as! String
        self.renterVehicle = reservation["userVehicle"] as! String
        self.start = reservation["start"] as! String
        self.end = reservation["end"] as! String
        self.reservationType = reservation["reservationType"] as! String
        self.access = reservation["access"] as! String
        self.hours = reservation["hours"] as! String
        self.totalPrice = reservation["totalPrice"] as! Double
        self.reservationCancelledByRentor = reservation["reservationCancelledByRentor"] as! Int
        self.reservationCancelledByOwner = reservation["reservationCancelledByOwner"] as! Int
        self.cancelledTimeStamp = reservation["cancelledTimeStamp"] as? String
    }
    
    func getReservationID() -> Int{
        return self.reservationID
    }
    func getSpotID() -> Int{
        return self.spotID
    }
    func getSpotAddress() -> String {
        return self.spotAddress
    }
    func getRenterName() -> String {
        return self.renterName
    }
    func getRenterVehicle() -> String {
        return self.renterVehicle
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
    func getTotalPrice() -> Double{
        return self.totalPrice
    }
    func getReservationCancelledByRentor() -> Int{
        return self.reservationCancelledByRentor
    }
    func getReservationCancelledByOwner() -> Int{
        return self.reservationCancelledByOwner
    }
    func getCancelledTimeStamp() -> String {
        return self.cancelledTimeStamp
    }
}
