//
//  ChapterCell.swift
//  SpeedListners
//
//Created by Satyam Dwivedi on 16/06/23.
//

import UIKit

class ChapterCell: UITableViewCell {

    @IBOutlet weak var lbl_ChapterName: UILabel!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
  
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}

