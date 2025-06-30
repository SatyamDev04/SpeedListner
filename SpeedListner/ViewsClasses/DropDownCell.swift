//
//  MyCell1.swift
//  SpeedListners
//
//  Created by ravi on 21/08/22.
//

import UIKit
import DropDown

class MyCell1: DropDownCell {

    
    @IBOutlet weak var img1: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
