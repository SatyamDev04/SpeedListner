//
//  VerificationVC.swift
//  SpeedListners
//
//  Created by ravi on 8/08/22.
//

import UIKit

class VerificationVC: UIViewController,UITextFieldDelegate {

    @IBOutlet weak var txt4: UITextField!
    @IBOutlet weak var txt2: UITextField!
  
    @IBOutlet weak var txt3: UITextField!
    @IBOutlet weak var txt1: UITextField!
    @IBOutlet weak var txt_View4: UIView!
    @IBOutlet weak var txt_View3: UIView!
    @IBOutlet weak var txt_View2: UIView!
    @IBOutlet weak var txt_View1: UIView!
    var emailid:String!
    let loading = indicator()
    override func viewDidLoad() {
        super.viewDidLoad()
//        if traitCollection.userInterfaceStyle == .dark {
//            // Dark mode is active
//            darkModeEnabled()
//            print("Dark Mode is active")
//        } else {
//            // Light mode is active
//            lightModeEnabled()
//            print("Light Mode is active")
//        }

        txt1.delegate = self
        txt2.delegate = self
        txt3.delegate = self
        txt4.delegate = self
        
        txt1.addTarget(self, action: #selector(self.textFieldDidChange(textField:)), for: UIControl.Event.editingChanged)
        txt2.addTarget(self, action: #selector(self.textFieldDidChange(textField:)), for: UIControl.Event.editingChanged)
        txt3.addTarget(self, action: #selector(self.textFieldDidChange(textField:)), for: UIControl.Event.editingChanged)
        txt4.addTarget(self, action: #selector(self.textFieldDidChange(textField:)), for: UIControl.Event.editingChanged)
        
        
        self.txt_View1.layer.borderWidth = 1
        self.txt_View1.layer.cornerRadius = 5
        self.txt_View1.layer.borderColor = UIColor(red:70/255, green:0/255, blue:100/255, alpha: 1).cgColor
        
        self.txt_View2.layer.borderWidth = 1
        self.txt_View2.layer.cornerRadius = 5
        self.txt_View2.layer.borderColor = UIColor(red:70/255, green:0/255, blue:100/255, alpha: 1).cgColor
        
        self.txt_View3.layer.borderWidth = 1
        self.txt_View3.layer.cornerRadius = 5
        self.txt_View3.layer.borderColor = UIColor(red:70/255, green:0/255, blue:100/255, alpha: 1).cgColor
        
        self.txt_View4.layer.borderWidth = 1
        self.txt_View4.layer.cornerRadius = 5
        self.txt_View4.layer.borderColor = UIColor(red:70/255, green:0/255, blue:100/255, alpha: 1).cgColor

        
    }
    
    @objc func textFieldDidChange(textField: UITextField){
            let text = textField.text
            if  text?.count == 1 {
                switch textField{
                case txt1:
                    txt2.becomeFirstResponder()
                case txt2:
                    txt3.becomeFirstResponder()
                case txt3:
                    txt4.becomeFirstResponder()
                case txt4:
                    txt4.resignFirstResponder()
                default:
                    break
                }
            }
            if  text?.count == 0 {
                switch textField{
                case txt1:
                    txt1.becomeFirstResponder()
                case txt2:
                    txt1.becomeFirstResponder()
                case txt3:
                    txt2.becomeFirstResponder()
                case txt4:
                    txt3.becomeFirstResponder()
                default:
                    break
                }
            }
            else{

            }
        }
    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    

    @IBAction func btnSubmit_Action(_ sender: Any) {
        
        if (txt1.text == "") || (txt2.text == "") || (txt3.text == "") || (txt4.text == "")  {
            
            AlertController.alert(title: "", message: "Please enter Otp")
            
        } else {
      
        let otp = "\((txt1.text)!)\((txt2.text)!)\((txt3.text)!)\((txt4.text)!)"
            
            let jsonDict : [String:Any] = ["email" :emailid! ,"otp" : otp]
       
        print(jsonDict,"jsonDict")
        
        let loginURL = baseURL.baseURL + appEndPoints.verify_otp //+appEndPoints.getOtpSignUp
        
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
              
              let myStringVariable = (dictData!["user_id"] as? String)!
              
              let myIntegerVariable = Int(myStringVariable) ?? 0
              
             UserDetail.shared.setUserId(String(myIntegerVariable))
              let userid1 = UserDetail.shared.getUserId()
            print(userid1, "user_id Verification VC")
                
              let vc = self.storyboard?.instantiateViewController(withIdentifier: "CreatePasswordVC") as! CreatePasswordVC
              vc.a = true
              vc.userid = myIntegerVariable
              self.navigationController?.pushViewController(vc, animated: true)
              
               // completionHandler("\(String(describing: dictData!["message"] as? String))", "")
            }  else    {
                let responseMessage =   "Invalid Code Please Try Again"//dictData!["msg"] as! String
                AlertController.alert(title: "", message: responseMessage)
            }
            //            hideHud()
        })
        
//            let vc = self.storyboard?.instantiateViewController(withIdentifier: "CreatePasswordVC") as! CreatePasswordVC
//            vc.a = true
//            self.navigationController?.pushViewController(vc, animated: true)
//
        }
        
    }
    
    @IBAction func btnResendOtp_Action(_ sender: Any) {
        let jsonDict : [String:Any] = ["email" : self.emailid!]
               print(jsonDict,"jsonDict")

               let loginURL = baseURL.baseURL + appEndPoints.signup //+appEndPoints.signup

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
                 if dictData!["msg_type"] as? String == "true" {
                     
                     self.showToast("Verification Code Sent Successfully.")

                 } else    {
                       let responseMessage = dictData!["msg"] as! String
                       AlertController.alert(title: "", message: responseMessage)
                   }
                   //            hideHud()
               })
    }
    
}

extension VerificationVC: UIScrollViewDelegate {

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

//extension VerificationVC {
//    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
//           super.traitCollectionDidChange(previousTraitCollection)
//
//           switch traitCollection.userInterfaceStyle {
//               case .dark: darkModeEnabled()   // Switch to dark mode colors, etc.
//               case .light: fallthrough
//               case .unspecified: fallthrough
//               default: lightModeEnabled()   // Switch to light mode colors, etc.
//           }
//       }
//    private func lightModeEnabled() {
//
//        txt1.attributedPlaceholder = NSAttributedString(string:"Enter Your Email/Phone", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 79/255, green: 0, blue: 100/255, alpha: 1)])
//        txt2.attributedPlaceholder = NSAttributedString(string:"Enter Your Email/Phone", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 79/255, green: 0, blue: 100/255, alpha: 1)])
//        txt3.attributedPlaceholder = NSAttributedString(string:"Enter Your Email/Phone", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 79/255, green: 0, blue: 100/255, alpha: 1)])
//        txt4.attributedPlaceholder = NSAttributedString(string:"Enter Your Email/Phone", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 79/255, green: 0, blue: 100/255, alpha: 1)])
//
//    }
//    private func darkModeEnabled() {
//        txt1.attributedPlaceholder = NSAttributedString(string:"Enter Your Email/Phone", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
//        txt2.attributedPlaceholder = NSAttributedString(string:"Enter Your Email/Phone", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
//        txt3.attributedPlaceholder = NSAttributedString(string:"Enter Your Email/Phone", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
//        txt4.attributedPlaceholder = NSAttributedString(string:"Enter Your Email/Phone", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
//    }
//}
//
//
