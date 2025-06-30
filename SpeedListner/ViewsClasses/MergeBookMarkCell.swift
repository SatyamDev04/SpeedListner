//
//  MergeBookMarkCell.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 06/05/25.
//

import UIKit

class MergeBookMarkCell: UITableViewCell {
    
   @IBOutlet weak var playBtn: UIButton!
   @IBOutlet weak var transcriptionBtn: UIButton!
   @IBOutlet weak var emailBtn: UIButton!
   @IBOutlet weak var bookmarkTimelbl: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
       
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    
}
