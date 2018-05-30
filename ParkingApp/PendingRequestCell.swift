//
//  PendingRequestCell.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import Foundation
import UIKit

class PendingRequestCell: UITableViewCell {
    
    @IBOutlet var spotAddressLabel: UILabel!
    @IBOutlet var detailsLabel: UILabel!
    
    var spotDetails:String!
    var spot:ParkingSpot!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
