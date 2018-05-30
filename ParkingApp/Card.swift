//
//  Card.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import Foundation

/*
 Class to assist with managing credit/debit cards
*/
class Card {
    private var cardIsDefault:String!
    private var last2:String!
    private var expiration:String!
    private var cardString:String!
    private var token:String!
    
    init(card: [String : AnyObject]) {
        self.cardIsDefault = String(describing: card["cardIsDefault"]!)
        self.last2 = String(describing: card["last2"]!)
        self.expiration = String(describing: card["expirationMonth"]!) + "/" + String(describing: card["expirationYear"]!)
        self.cardString = "**" + self.last2! + " Exp: " + self.expiration!
        if cardIsDefault == "true" || cardIsDefault == "1" {
            cardString = cardString + " - default"
        }
        self.token = String(describing: card["token"]!)
    }
    
    func getCardString() -> String {
        return self.cardString!
    }
    
    func getToken() -> String {
        return self.token!
    }
    
}
