//
//  Mycell.swift
//  SpeedListners
//
//  Created by ravi on 10/08/22.
//

import UIKit
import DropDown

class Mycell: DropDownCell {
    @IBOutlet open weak var optionLabel1: UILabel!
    @IBOutlet weak var img11: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
