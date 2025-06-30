//
//  CellData.swift
//  SpeedListners
//
//  Created by ravi on 23/08/22.
//

import UIKit

class CellData: UITableViewCell {

    @IBOutlet weak var headerLeadingConstraints: NSLayoutConstraint!
    @IBOutlet weak var lblDesc: UILabel!
    @IBOutlet weak var img: UIImageView!
    @IBOutlet weak var lblHeader: UILabel!
    @IBOutlet weak var lblSerialNumber: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
