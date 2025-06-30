//
//  ResetPasswordVC.swift
//  SpeedListners
//
//  Created by ravi on 9/08/22.
//

import UIKit

protocol DelegateforResetPassword {
    func MethodforPop()
    
}

class ResetPasswordVC: UIViewController {
    
    @IBOutlet weak var txt_ConfirmPassword: UITextField!
    @IBOutlet weak var txt_NewPassword: UITextField!
    @IBOutlet weak var txt_oldPassword: UITextField!
    var delegate:DelegateforResetPassword? = nil
    var iconClick = true
    @IBOutlet weak var submitBtn: UIButton!
    @IBOutlet weak var view_submit: UIView!
    @IBOutlet weak var view_main: UIView!
    @IBOutlet weak var view_confirmPassword: UIView!
    @IBOutlet weak var view_newPassword: UIView!
    @IBOutlet weak var view_oldPassword: UIView!
    let loading = indicator()
    override func viewDidLoad() {
        super.viewDidLoad()

        if traitCollection.userInterfaceStyle == .dark {
            // Dark mode is active
            darkModeEnabled()
            print("Dark Mode is active")
        } else {
            // Light mode is active
            lightModeEnabled()
            print("Light Mode is active")
        }
        self.tabBarController?.tabBar.isHidden = true

        self.view_main.layer.cornerRadius = 10
        self.view_submit.layer.cornerRadius = 25
        self.submitBtn.layer.cornerRadius = 25
        self.view_confirmPassword.layer.cornerRadius = 25
        self.view_newPassword.layer.cornerRadius = 25
        self.view_oldPassword.layer.cornerRadius = 25
        
        self.view_confirmPassword.layer.borderWidth = 1
        self.view_confirmPassword.layer.borderColor = UIColor(red:70/255, green:0/255, blue:100/255, alpha: 1).cgColor
        
        self.view_newPassword.layer.borderWidth = 1
        self.view_newPassword.layer.borderColor = UIColor(red:70/255, green:0/255, blue:100/255, alpha: 1).cgColor
        
        self.view_oldPassword.layer.borderWidth = 1
        self.view_oldPassword.layer.borderColor = UIColor(red:70/255, green:0/255, blue:100/255, alpha: 1).cgColor
    }
    
   func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true);
        //navigationController?.navigationBar.hidden = true // for navigation bar hide
       UIApplication.shared.isStatusBarHidden = false; // for status bar hide
    }
    @IBAction func btnEye_OldPasswordAction(_ sender: Any) {
        if(iconClick == true) {
                    txt_oldPassword.isSecureTextEntry = false
                } else {
                    txt_oldPassword.isSecureTextEntry = true
                }

                iconClick = !iconClick
    }
    @IBAction func btnEye_NewPasswordAction(_ sender: Any) {
        if(iconClick == true) {
                    txt_NewPassword.isSecureTextEntry = false
                } else {
                    txt_NewPassword.isSecureTextEntry = true
                }

                iconClick = !iconClick
    }
    
    @IBAction func btnEye_ConfirmPasswordAction(_ sender: Any) {
        if(iconClick == true) {
                    txt_ConfirmPassword.isSecureTextEntry = false
                } else {
                    txt_ConfirmPassword.isSecureTextEntry = true
                }

                iconClick = !iconClick
    }
    
    @IBAction func btnCross_Action(_ sender: Any) {
        self.delegate?.MethodforPop()
       
    }
    
    @IBAction func btnSubmit_Action(_ sender: Any) {
        
        if txt_NewPassword.text == txt_ConfirmPassword.text {
            let userid = UserDetail.shared.getUserId()
            let jsonDict : [String:Any] = ["user_id" :"\(userid)" ,"Old_password" : txt_oldPassword.text!,"new_password" : txt_NewPassword.text!,"confirmnew_password" : txt_ConfirmPassword.text!]
       
        print(jsonDict,"jsonDict")
        
        let loginURL = baseURL.baseURL + appEndPoints.reset_password //+appEndPoints.create_password
        
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
          if dictData!["msg_type"] as? String == "success"{
              
              self.delegate?.MethodforPop()

               // completionHandler("\(String(describing: dictData!["message"] as? String))", "")
            }  else    {
                let responseMessage =   "Old password not match.Please Try Again."//dictData!["msg"] as! String
                AlertController.alert(title: "", message: responseMessage)
            }
            //            hideHud()
        })
//        self.delegate?.MethodforPop()
        } else {
            let responseMessage =  "New Password and Confirm New Password do not match. Please try again." //"//dictData!["msg"] as! String
            AlertController.alert(title: "", message: responseMessage)
        }
    }
    
}
//MARK: - Dark/Light mode logic
extension ResetPasswordVC {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
           super.traitCollectionDidChange(previousTraitCollection)

           switch traitCollection.userInterfaceStyle {
               case .dark: darkModeEnabled()   // Switch to dark mode colors, etc.
               case .light: fallthrough
               case .unspecified: fallthrough
               default: lightModeEnabled()   // Switch to light mode colors, etc.
           }
       }
    private func lightModeEnabled() {

        txt_ConfirmPassword.attributedPlaceholder = NSAttributedString(string:"Confirm New Password", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 40/255, green: 0, blue: 71/255, alpha: 1)])
        txt_NewPassword.attributedPlaceholder = NSAttributedString(string:"Create New Password", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 40/255, green: 0, blue: 71/255, alpha: 1)])
        txt_oldPassword.attributedPlaceholder = NSAttributedString(string:"Confirm New Password", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 40/255, green: 0, blue: 71/255, alpha: 1)])
    }
    private func darkModeEnabled() {

        txt_ConfirmPassword.attributedPlaceholder = NSAttributedString(string:"Confirm New Password", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        txt_NewPassword.attributedPlaceholder = NSAttributedString(string:"Create New Password", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        txt_oldPassword.attributedPlaceholder = NSAttributedString(string:"Confirm New Password", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    }
}


