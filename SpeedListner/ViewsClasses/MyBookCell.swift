//
//  MyBookCell.swift
//  SpeedListners
//
//  Created by ravi on 9/08/22.
//

import UIKit

class MyBookCell: UITableViewCell {

    @IBOutlet weak var lblBookAuthor: UILabel!
    @IBOutlet weak var lblBookName: UILabel!
    @IBOutlet weak var btnSelect: UIButton!
    @IBOutlet weak var folderIcon: UIImageView!
    @IBOutlet weak var selectBtnBgView: UIView!
    @IBOutlet weak var viewBgView: UIView!
    var onSelectButtonTapped: (() -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    @IBAction func selectButtonTapped(_ sender: UIButton) {
        onSelectButtonTapped?()
    }

}
