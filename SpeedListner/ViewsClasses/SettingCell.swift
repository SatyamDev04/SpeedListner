//
//  SettingCell.swift
//  SpeedListners
//
//  Created by ravi on 8/09/22.
//

import UIKit

class SettingCell: UITableViewCell {

    @IBOutlet weak var lblLeadingContraints: NSLayoutConstraint!
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var lbl_name: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
