//
//  LogoutPopup2VC.swift
//  SpeedListners
//
//  Created by ravi on 24/08/22.
//

import UIKit

class LogoutPopup2VC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func OkButton_Action(_ sender: Any) {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
        vc.hidesBottomBarWhenPushed = true
     
       UserDetail.shared.setPreviousUserId(UserDetail.shared.getUserId())
        print(UserDetail.shared.getUserId(),"onLogout",UserDetail.shared.getPreviousUserId())
        UserDetail.shared.setUserId("")
        UserDefaults.standard.set(0, forKey: "subs")
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    @IBAction func btnCross_Action(_ sender: Any) {
        
        self.navigationController?.popViewController(animated: true)
    }
    
   
}
