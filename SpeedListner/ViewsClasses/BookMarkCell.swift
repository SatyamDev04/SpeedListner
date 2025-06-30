//
//  BookMarkCell.swift
//  SpeedListners
//
//  Created by ravi on 19/08/22.
//

import UIKit
import DropDown


class BookMarkCell: UITableViewCell{
    
    @IBOutlet weak var btnReadMore: UIButton!
    @IBOutlet weak var lblNoteDesc: UILabel!
    @IBOutlet weak var lblNote: UILabel!
    @IBOutlet weak var btnMenu: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()

        //self.tblSort.register(UINib(nibName: "tableSortCell", bundle: nil), forCellReuseIdentifier: "tableSortCell")
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

      
    }
    
 
    
}
