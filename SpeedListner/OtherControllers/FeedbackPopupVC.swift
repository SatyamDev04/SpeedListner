//
//  FeedbackPopupVC.swift
//  SpeedListners
//
//  Created by ravi on 24/08/22.
//

import UIKit
protocol DelegateforFeedbackPopUp {
    func MethodforPop()
    
}
class FeedbackPopupVC: UIViewController {
    
    var delegateforfeedbackPopup:DelegateforFeedbackPopUp? = nil
   
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnCross_Action(_ sender: Any) {
        self.delegateforfeedbackPopup?.MethodforPop()
       // self.navigationController?.popViewController(animated: true)
    }
    @IBAction func btnYes_Action(_ sender: Any) {
        self.delegateforfeedbackPopup?.MethodforPop()
      //  self.navigationController?.popViewController(animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
