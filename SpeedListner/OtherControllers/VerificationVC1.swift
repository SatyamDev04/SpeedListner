//
//  VerificationVC1.swift
//  SpeedListners
//
//  Created by ravi on 8/08/22.
//

import UIKit

class VerificationVC1: UIViewController,UITextFieldDelegate {
    @IBOutlet weak var txt4: UITextField!
    @IBOutlet weak var txt2: UITextField!
  
    @IBOutlet weak var txt3: UITextField!
    @IBOutlet weak var txt1: UITextField!
    @IBOutlet weak var txt_View4: UIView!
    @IBOutlet weak var txt_View3: UIView!
    @IBOutlet weak var txt_View2: UIView!
    @IBOutlet weak var txt_View1: UIView!
    
    var EmailPhone:String!
    let loading = indicator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
     
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
            
            let jsonDict : [String:Any] = ["email" :EmailPhone! ,"otp" : otp]
       
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
                
              let vc = self.storyboard?.instantiateViewController(withIdentifier: "CreatePasswordVC") as! CreatePasswordVC
              
              let myStringVariable = (dictData!["user_id"] as? String)!
              let myIntegerVariable = Int(myStringVariable) ?? 0
              print(myIntegerVariable, "user_id Verification VC")
              vc.a = false
              vc.userid = myStringVariable
              
              self.navigationController?.pushViewController(vc, animated: true)
              
            }  else    {
                let responseMessage =   "Invalid Code Please Try Again"
                AlertController.alert(title: "", message: responseMessage)
            }
           
        })
        }
        
       
    }
    
    @IBAction func btnResendOtp_Action(_ sender: Any) {
        
        let jsonDict : [String:Any] = ["email" : self.EmailPhone!]
               print(jsonDict,"jsonDict")

               let loginURL = baseURL.baseURL + appEndPoints.send_forget_password //+appEndPoints.signup

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
                 if dictData!["msg_type"] as? String == "success" {
                     
                     self.showToast("Verification Code Sent Successfully.")

                 } else    {
                       let responseMessage = dictData!["msg"] as! String
                       AlertController.alert(title: "", message: responseMessage)
                   }
               })
        
        
    }
    
}

extension VerificationVC1: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        //--- Change Scroll View Indicator Color ---//
        if #available(iOS 13, *) {
            let verticalIndicatorView = (scrollView.subviews[(scrollView.subviews.count - 1)].subviews[0])
            let horizontalIndicatorView = (scrollView.subviews[(scrollView.subviews.count - 2)].subviews[0])
          
            
            verticalIndicatorView.backgroundColor = UIColor.clear
            verticalIndicatorView.backgroundColor = UIColor(red: 79/255, green: 0/255, blue: 100/255, alpha: 1)
            
            horizontalIndicatorView.backgroundColor = UIColor.clear
            horizontalIndicatorView.backgroundColor = UIColor(red: 79/255, green: 0/255, blue: 100/255, alpha: 1)
            
        } else {
            
          
            
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



