//
//  SignUpVC.swift
//  SpeedListners
//
//  Created by ravi on 8/08/22.
//

import UIKit

class SignUpVC: UIViewController {
    
    @IBOutlet weak var imgSelect: UIImageView!
    @IBOutlet weak var btnSelect: UIButton!
    @IBOutlet weak var txt_Email: UITextField!
    @IBOutlet weak var view_SignUp: UIView!
    @IBOutlet weak var viewEmail: UIView!
    var flag = false
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
        
        self.view_SignUp.layer.borderWidth = 1
        self.view_SignUp.layer.borderColor = UIColor(red:70/255, green:0/255, blue:100/255, alpha: 1).cgColor
        setButtonImage()
       
        self.viewEmail.layer.borderWidth = 1
        self.viewEmail.layer.borderColor = UIColor(red:70/255, green:0/255, blue:100/255, alpha: 1).cgColor
        
    }
    
    func validateEmail(YourEMailAddress: String) -> Bool {
        let REGEX: String
        REGEX = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,3}"
        return NSPredicate(format: "SELF MATCHES %@", REGEX).evaluate(with: YourEMailAddress)
    }
    func validation() -> Bool {
        
        if txt_Email.text?.count == 0 {
            self.popupAlert(title: "Error", message: "Email can't be empty.", actionTitles: ["Ok"], actions:[{action1 in}])
            return false
        
        } else if txt_Email.text?.isNumeric == false {
            if  !validateEmail(YourEMailAddress: txt_Email.text!){
                self.popupAlert(title: "Error", message: "Please enter valid email.", actionTitles: ["Ok"], actions:[{action1 in}])
                return false
            }
            
        } else if txt_Email.text?.isNumeric == true || txt_Email.text!.count != 10 {
            if  !txt_Email.text!.isValidPhone(){
                self.popupAlert(title: "Error", message: "Please enter valid phone number.", actionTitles: ["Ok"], actions:[{action1 in}])
                return false
            }
        
    }
        
        return true
    }
    @IBAction func btn_AgreeAction(_ sender: UIButton) {
        flag = !flag
        setButtonImage()
        
    }
    func setButtonImage(){
            let imgName = flag ? "ic_outline-check-box" : "ic_outline-check-box-1"
            let image1 = UIImage(named: "\(imgName).png")!
       // imgSelect.image(UIImage(named: "\(image1)"))
            self.btnSelect.setImage(image1, for: .normal)
        }

    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func BtnSignUp_Action(_ sender: Any) {
        print("Sign up Button Action")
       
        guard validation() else {
            return }
        
        let jsonDict : [String:Any] = ["email" : self.txt_Email.text ?? ""]
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

                     if self.flag == true {
                         self.showToast("Sign up successfully.")
                         PlayerManager.shared.email = self.txt_Email.text ?? ""
                             DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
                         let vc = self.storyboard?.instantiateViewController(withIdentifier: "VerificationVC") as! VerificationVC
                                 vc.emailid = txt_Email.text ?? ""
                            
                                 self.navigationController?.pushViewController(vc, animated: true) } }else {
                                 self.popupAlert(title: "Error", message: "Please Select Agree With Terms & Conditions To Proceed.", actionTitles: ["Ok"], actions:[{action1 in}])
                                 return
                             }
                     

                 } else    {
                     
                       let responseMessage = dictData!["msg"] as! String
                       AlertController.alert(title: "", message: responseMessage)
                   }
                   //            hideHud()
               })
        
        
//        if flag == true {
//        let vc = self.storyboard?.instantiateViewController(withIdentifier: "VerificationVC") as! VerificationVC
//            self.navigationController?.pushViewController(vc, animated: true) } else {
//                self.popupAlert(title: "Error", message: "Please Select Agree With Terms & Conditions To Proceed.", actionTitles: ["Ok"], actions:[{action1 in}])
//                return
//            }
   
    }
    
    @IBAction func btnLogin_Action(_ sender: Any) {
        print("Login Button Action")
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
        self.navigationController?.pushViewController(vc, animated: true)

        
    }
    
}
extension SignUpVC: UIScrollViewDelegate {

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
extension SignUpVC {
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

        txt_Email.attributedPlaceholder = NSAttributedString(string:"Enter Your Email/Phone", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 40/255, green: 0, blue: 70/255, alpha: 1)])
       
    }
    private func darkModeEnabled() {
        txt_Email.attributedPlaceholder = NSAttributedString(string:"Enter Your Email/Phone", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    
    }
}
