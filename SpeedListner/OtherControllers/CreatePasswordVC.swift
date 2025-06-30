//
//  CreatePasswordVC.swift
//  SpeedListners
//
//  Created by ravi on 8/08/22.
//

import UIKit

class CreatePasswordVC: UIViewController {
    
    var a:Bool = false
    var userid : Int!
    
    var iconClick = true

    @IBOutlet weak var view_ConfirmPassword: UIView!
    @IBOutlet weak var view_CreatePassword: UIView!
    @IBOutlet weak var txt_ConfirmPassword: UITextField!
    @IBOutlet weak var txt_NewPassword: UITextField!
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

        self.view_ConfirmPassword.layer.borderWidth = 1
        self.view_ConfirmPassword.layer.borderColor = UIColor(red:70/255, green:0/255, blue:100/255, alpha: 1).cgColor
        
        self.view_CreatePassword.layer.borderWidth = 1
        self.view_CreatePassword.layer.borderColor = UIColor(red:70/255, green:0/255, blue:100/255, alpha: 1).cgColor
        
    }
    
    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    

    @IBAction func btnEye_NewPassword(_ sender: Any) {
        if(iconClick == true) {
            txt_NewPassword.isSecureTextEntry = false
                } else {
                    txt_NewPassword.isSecureTextEntry = true
                }

                iconClick = !iconClick
    }
    @IBAction func btnEye_ConfirmPassword_Action(_ sender: Any) {
        if(iconClick == true) {
            txt_ConfirmPassword.isSecureTextEntry = false
                } else {
                    txt_ConfirmPassword.isSecureTextEntry = true
                }

                iconClick = !iconClick
    }
    @IBAction func btnSubmit_Action(_ sender: Any) {
        guard validation() else {
            return }
        
        if txt_NewPassword.text == txt_ConfirmPassword.text {
            
            let jsonDict : [String:Any] = ["user_id" :"\(userid!)" ,"password" : txt_ConfirmPassword.text!]
       
        print(jsonDict,"jsonDict")
        
        let loginURL = baseURL.baseURL + appEndPoints.create_password //+appEndPoints.create_password
        
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
          if dictData!["msg_type"] as? String == "true"{
              
              if self.a == false{
                      let vc = self.storyboard?.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
                          self.navigationController?.pushViewController(vc, animated: true) }
                      else {
              
              
                          let vc = self.storyboard?.instantiateViewController(withIdentifier: "CreateProfileVC") as! CreateProfileVC
                          vc.userid = String(self.userid)
                              self.navigationController?.pushViewController(vc, animated: true)
                              }

               // completionHandler("\(String(describing: dictData!["message"] as? String))", "")
            }  else    {
                let responseMessage =   "Invalid Code Please Try Again"//dictData!["msg"] as! String
                AlertController.alert(title: "", message: responseMessage)
            }
            //            hideHud()
        })
            
            
//        if a == false{
//        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
//            self.navigationController?.pushViewController(vc, animated: true) }
//        else {
//
//
//            let vc = self.storyboard?.instantiateViewController(withIdentifier: "CreateProfileVC") as! CreateProfileVC
//                self.navigationController?.pushViewController(vc, animated: true)
//                }
//        }
           
        } else {
                    showAlert(for: "Password and confirm password should be same.")
                }
        
    }
    func validpassword(mypassword : String) -> Bool
        {
            let passwordreg =  ("(?=.*[A-Z])(?=.*[0-9])(?=.*[a-z])(?=.*[@#$%^&*]).{8,}")
            let passwordtesting = NSPredicate(format: "SELF MATCHES %@", passwordreg)
            return passwordtesting.evaluate(with: mypassword)
        }
    func validation() -> Bool {
        
     
        if txt_NewPassword.text?.count == 0 {
        self.popupAlert(title: "Error", message: "New password can't be empty.", actionTitles: ["Ok"], actions:[{action1 in}])
        return false
    }
        if !validpassword(mypassword: txt_NewPassword.text!){
            self.popupAlert(title: "Error", message: "New password should be minimum 8 characters. Atleast 1 Alphabet, 1 Special character and 1 Numeric value.", actionTitles: ["Ok"], actions:[{action1 in}])
            return false
           
        }
        
        if txt_ConfirmPassword.text?.count == 0 {
        self.popupAlert(title: "Error", message: "Confirm password can't be empty.", actionTitles: ["Ok"], actions:[{action1 in}])
        return false
    }
      if !validpassword(mypassword: txt_ConfirmPassword.text!){
            self.popupAlert(title: "Error", message: "Confirm password should be minimum 8 characters. Atleast 1 Alphabet, 1 Special character and 1 Numeric value.", actionTitles: ["Ok"], actions:[{action1 in}])
            return false
            
        }
        
        return true
    }
    

}

extension CreatePasswordVC: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        //--- Change Scroll View Indicator Color ---//
        if #available(iOS 13, *) {
            let verticalIndicatorView = (scrollView.subviews[(scrollView.subviews.count - 1)].subviews[0])
            let horizontalIndicatorView = (scrollView.subviews[(scrollView.subviews.count - 2)].subviews[0])
            
            //let colors = [UIColor(named: "#E54F4F")!.cgColor, UIColor(named: "##E61C1C")!.cgColor, UIColor(named: "#8E0202")!.cgColor]
            
            verticalIndicatorView.backgroundColor = UIColor.clear
            verticalIndicatorView.backgroundColor = UIColor(red: 79/255, green: 0/255, blue: 100/255, alpha: 1)
            //verticalIndicatorView.setGradient(colors: colors, angle: 90.0)
            
            horizontalIndicatorView.backgroundColor = UIColor.clear
            horizontalIndicatorView.backgroundColor = UIColor(red: 79/255, green: 0/255, blue: 100/255, alpha: 1)
            
        } else {
            
           // let colors = [UIColor(named: "#E54F4F")!.cgColor, UIColor(named: "##E61C1C")!.cgColor, UIColor(named: "#8E0202")!.cgColor]
            
            if let verticalIndicatorView: UIImageView = (scrollView.subviews[(scrollView.subviews.count - 1)] as? UIImageView) {
                verticalIndicatorView.backgroundColor = UIColor.clear
                verticalIndicatorView.backgroundColor = UIColor(red: 79/255, green: 0/255, blue: 100/255, alpha: 1)
            }

            if let horizontalIndicatorView: UIImageView = (scrollView.subviews[(scrollView.subviews.count - 2)] as? UIImageView) {
                horizontalIndicatorView.backgroundColor = UIColor.clear
                horizontalIndicatorView.backgroundColor = UIColor(red: 79/255, green: 0/255, blue: 100/255, alpha: 1)
            }
        }
   }
}

//MARK: - Dark/Light mode logic
extension CreatePasswordVC {
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

        txt_NewPassword.attributedPlaceholder = NSAttributedString(string:"Create New Password", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 40/255, green: 0, blue: 71/255, alpha: 1)])
        txt_ConfirmPassword.attributedPlaceholder = NSAttributedString(string:"Confirm New Password", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 40/255, green: 0, blue: 71/255, alpha: 1)])
    }
    private func darkModeEnabled() {

        txt_NewPassword.attributedPlaceholder = NSAttributedString(string:"Create New Password", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        txt_ConfirmPassword.attributedPlaceholder = NSAttributedString(string:"Confirm New Password", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    }
}




