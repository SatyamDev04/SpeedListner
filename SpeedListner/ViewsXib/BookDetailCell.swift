//
//  BookDetailCell.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 07/04/25.
//

import UIKit

class BookDetailCell: UITableViewCell{
var delegateBookDetails:BookDetailsCellDelegate? = nil
@IBOutlet weak var btnPlay: UIButton!
@IBOutlet weak var lbl_AutherName: UILabel!
@IBOutlet weak var lbl_subFolderCount: UILabel!
@IBOutlet weak var lbl_BookName: UILabel!
@IBOutlet weak var lbl_comlition: UILabel!
@IBOutlet weak var img: UIImageView!
@IBOutlet var folderIcon_img: UIImageView!
@IBOutlet weak var btnSelect: UIButton!
@IBOutlet weak var selectBtnBgView: UIView!
@IBOutlet weak var stackBgView: UIView!
var onSelectButtonTapped: (() -> Void)?



var type: BookCellType = .book {
    didSet {
        self.folderIcon_img.isHidden = true
        switch self.type {
        case .file: break
        case .playlist:
            self.folderIcon_img.isHidden = false
        default: break
                
        }
    }
    
}
var playbackState: PlaybackState = PlaybackState.stopped {
    didSet {
        UIView.animate(withDuration: 0.1, animations: {
            switch self.playbackState {
                case .playing:
                self.btnPlay.setImage(UIImage(named: "21"), for: .normal)

                case .paused:
                self.btnPlay.setImage(UIImage(named: "29"), for: .normal)

                default:
                self.btnPlay.setImage(UIImage(named: "29"), for: .normal)

            }
        })
    }
}

var progress: Double {
    get {
        return 0
    }
    set {
        self.lbl_comlition.text = "\(Int(round(newValue * 100)))%"
      
    }
}
override func awakeFromNib() {
    super.awakeFromNib()
    
    // Initialization code
}

override func setSelected(_ selected: Bool, animated: Bool) {
    super.setSelected(selected, animated: animated)

    // Configure the view for the selected state
}
@IBAction func btnPlayIndex_Action(_ sender: UIButton) {
    var index = btnPlay.tag
    delegateBookDetails?.sendIndex(Index: index, sender: sender)
    
}
@IBAction func selectButtonTapped(_ sender: UIButton) {
    onSelectButtonTapped?()
}
}
