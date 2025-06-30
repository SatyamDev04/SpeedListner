//
//  MessageAccountDeletedVC.swift
//  SpeedListners
//
//  Created by ravi on 22/08/22.
//

import UIKit

class MessageAccountDeletedVC: UIViewController {
    
    @IBOutlet weak var txt_Delete: UITextField!
    let loading = indicator()
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnSubmit_Action(_ sender: Any) {
        if txt_Delete.text == "DELETE"{
            let userid = UserDetail.shared.getUserId()
            let jsonDict : [String:Any] = ["user_id" :"\(userid)"]
            
            print(jsonDict,"jsonDict")
            
            let loginURL = baseURL.baseURL + appEndPoints.delete_user //+appEndPoints.create_password
            
            print(loginURL, "loginURL")
            
            self.loading.showActivityIndicator(uiView: self.view)
            
            WebService.shared.servicePostWithFoamDataParameter(loginURL, jsonDict, withCompletion:  { (json, statusCode) in
                self.loading.hideActivityIndicator(uiView: self.view)
                let dict = "\(json)"
                var dictData : [String:Any]?
                if let data = dict.data(using: .utf8) {
                    do {
                        dictData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                        
                        
                    } catch {
                        print(error.localizedDescription)
                    }
                }
                if dictData!["success"] as? Bool == true {
                    
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "AccountDeletedVC") as! AccountDeletedVC
                    UserDetail.shared.removeUserId()
                    self.navigationController?.pushViewController(vc, animated: false)
                    
                    // completionHandler("\(String(describing: dictData!["message"] as? String))", "")
                }  else    {
                    //            let responseMessage =   "Old password not match.Please Try Again."//dictData!["msg"] as! String
                    //            AlertController.alert(title: "", message: responseMessage)
                }
                //            hideHud()
            }) } else {
                let responseMessage =   "Please type DELETE in capitals"//dictData!["msg"] as! String
                AlertController.alert(title: "", message: responseMessage)
            }
        
        
        //        let vc = self.storyboard?.instantiateViewController(withIdentifier: "AccountDeletedVC") as! AccountDeletedVC
        //                self.navigationController?.pushViewController(vc, animated: true)
        
    }
    
    @IBAction func btnCross_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnClose_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
}
