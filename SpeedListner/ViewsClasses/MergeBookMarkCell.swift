//
//  MergeBookMarkCell.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 06/05/25.
//

import UIKit

class MergeBookMarkCell: UITableViewCell {
    
    @IBOutlet weak var optionBtn: UIButton!
    @IBOutlet weak var playBtn: UIButton!
    @IBOutlet weak var transcriptionBtn: UIButton!
    @IBOutlet weak var bookmarkTimelbl: UILabel!
    @IBOutlet weak var detailtxt: UILabel!
    @IBOutlet weak var starBG: UIView!
    @IBOutlet weak var isStarBookMark: UIButton!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var transSumryLable: UILabel!
    var delegate: BookMarkCellDelegate? = nil
    override func awakeFromNib() {
        super.awakeFromNib()
       
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }
    @IBAction func btnDot_Action(_ sender: UIButton) {
        
        let index = self.optionBtn.tag
        self.delegate?.buttonTapped(index: index, sender: sender)
    
        
    }
    
    
}
