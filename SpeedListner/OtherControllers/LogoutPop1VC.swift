//
//  LogoutPop1VC.swift
//  SpeedListners
//
//  Created by ravi on 24/08/22.
//

import UIKit

class LogoutPop1VC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func bntLogout_Action(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LogoutPopup2VC") as! LogoutPopup2VC
        
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func btnCancel_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnCross_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
}
