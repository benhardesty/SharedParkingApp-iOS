//
//  MyCustomTableViewCell.swift
//  ParkingApp
//
//  Copyright © 2017 Benjamin Hardesty. All Rights Reserved.
//

import UIKit

class MyCustomTableViewCell: UITableViewCell {
    
    @IBOutlet var menuItemLabel: UILabel!
    
    @IBOutlet weak var menuIconImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        menuItemLabel.text = ""
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
