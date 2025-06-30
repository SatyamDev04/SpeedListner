//
//  UploadFileCell.swift
//  SpeedListners
//
//  Created by ravi on 12/08/22.
//

import UIKit

class UploadFileCell: UITableViewCell {
    var isRunning = false
    var progressBarTimer: Timer!
    @IBOutlet weak var progressView1: UIProgressView!
    
    let progress = Progress(totalUnitCount: 100)
       
    @IBOutlet weak var lbl_Size: UILabel!
    @IBOutlet weak var img_Status: UIImageView!
//    @IBOutlet weak var img_processing: UIImageView!
    @IBOutlet weak var lbl_ProcesingStatus: UILabel!
    @IBOutlet weak var lbl_BookName: UILabel!
    @IBOutlet weak var imgProfile: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        

    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}





    //        progressView1.progress = 0.0
    //
    //        progressView1.layer.cornerRadius = 10
    //        progressView1.clipsToBounds = true
    //        progressView1.layer.sublayers![1].cornerRadius = 10
    //        progressView1.subviews[1].clipsToBounds = true
    //        if(isRunning){
    //            progressBarTimer.invalidate()
    ////            btn.setTitle("Start", for: .normal)
    //        }
    //        else{
    ////        btn.setTitle("Stop", for: .normal)
    //            progressView1.progress = 0.0
    //        self.progressBarTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(UploadFileCell.updateProgressView), userInfo: nil, repeats: true)
    //
    //        }
    //        isRunning = !isRunning
            
       // }
        
    //    @objc func updateProgressView(_ sender: UIProgressView){
    //
    //        let cell: UploadFileCell = tblV.cellForRow(at: NSIndexPath(row: sender.tag, section: 0) as IndexPath) as! UploadFileCell
    //       // let cell = tblV.cellForRow(at: indexPath)! as! UploadFileCell
    //
    //       // let cell = tblV.cellForRow(at: index) as! UploadFileCell
    //
    //        print(index,"indexinsidecell")
    //        cell.progressView1.progress += 0.1
    //       // index = ((index + 1) as NSIndexPath) as IndexPath
    //
    //        cell.progressView1.setProgress(cell.progressView1.progress, animated: true)
    //       // progressBarTimer.invalidate()
    //
    //        isRunning = false
    //
    //
    ////        if(cell.progressView1.progress == 1.0)
    ////        {
    ////            progressBarTimer.invalidate()
    ////            isRunning = false
    ////
    ////        }
    //    }
        
        
        
    //
    //    @objc func updateProgressView(){
    //        progressView1.progress += 0.1
    //        progressView1.setProgress(progressView1.progress, animated: true)
    //        if(progressView1.progress == 1.0)
    //        {
    //            progressBarTimer.invalidate()
    //            isRunning = false
    //
    //        }
    //    }
