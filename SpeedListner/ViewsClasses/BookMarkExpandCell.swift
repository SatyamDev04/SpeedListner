//
//  BookMarkExpandCell.swift
//  SpeedListners
//
//  Created by ravi on 19/08/22.
//

import UIKit
import DropDown

protocol BookMarkCellDelegate  {
    
    func buttonTapped(index:Int,sender:UIButton)
  
}

class BookMarkExpandCell: UITableViewCell {
    
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var optionBtn: UIButton!
    @IBOutlet weak var bookmarkTimelbl: UILabel!
    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var bookmarkBtn: UIButton!
    @IBOutlet weak var detailtxt: UILabel!
    @IBOutlet weak var starBG: UIView!
    @IBOutlet weak var isStarBookMark: UIButton!
    
    var delegate: BookMarkCellDelegate? = nil
    let topMenu = DropDown()
   
    
    lazy var dropDowns: [DropDown] = {
        return [
            self.topMenu,
          
        ]
    }()
   
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    @IBAction func btnDot_Action(_ sender: UIButton) {
        
        let index = self.optionBtn.tag
        self.delegate?.buttonTapped(index: index, sender: sender)
        //self.delegate?.buttonDownload(index: index, sender: sender)
        


    
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
