//
//  DeleteAcountVC.swift
//  SpeedListners
//
//  Created by ravi on 22/08/22.
//

import UIKit

class DeleteAcountVC: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnYes_Action(_ sender: Any) {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "MessageAccountDeletedVC") as! MessageAccountDeletedVC
                self.navigationController?.pushViewController(vc, animated: false)


    }
    
    @IBAction func btnCross_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnNo_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }

}
