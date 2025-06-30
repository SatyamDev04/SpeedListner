//
//  LoginVC.swift
//  SpeedListners
//
//  Created by ravi on 5/08/22.
//

import UIKit

class LoginVC: UIViewController {
    
    @IBOutlet weak var txt_Password: UITextField!
    @IBOutlet weak var txt_EmailPhone: UITextField!
    @IBOutlet weak var view_Login: UIView!
    @IBOutlet weak var view_Password: UIView!
    @IBOutlet weak var viewEmail: UIView!
    @IBOutlet weak var upperCornerImg: UIImageView!
    @IBOutlet weak var bgImg: UIImageView!
    @IBOutlet weak var lowerCornerImg: UIImageView!
    
    var iconClick: Bool = true
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
        let userid = UserDetail.shared.getUserId()
   
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "TabBarVC") as! TabBarVC
       
        self.navigationController!.pushViewController(vc, animated: false)
        //}
        hidesBottomBarWhenPushed = true
        self.view_Login.layer.borderWidth = 1
        self.view_Login.layer.borderColor = UIColor(red:70/255, green:0/255, blue:100/255, alpha: 1).cgColor
        
        self.view_Password.layer.borderWidth = 1
        self.view_Password.layer.borderColor = UIColor(red:70/255, green:0/255, blue:100/255, alpha: 1).cgColor
        
        self.viewEmail.layer.borderWidth = 1
        self.viewEmail.layer.borderColor = UIColor(red:70/255, green:0/255, blue:100/255, alpha: 1).cgColor
         
        
    }
    
      
 
    @IBAction func btnEye_Password(_ sender: Any) {
        if(iconClick == true) {
            txt_Password.isSecureTextEntry = false
                } else {
                    txt_Password.isSecureTextEntry = true
                }

                iconClick = !iconClick
    }
    
    
    @IBAction func btnLogin_Action(_ sender: Any) {
        print("Login Button Action")
        
        guard validation() else {return}
        

        let jsonDict : [String:Any] = ["emailOrPhone" : self.txt_EmailPhone.text ?? "","password" : self.txt_Password.text ?? ""]
               print(jsonDict,"jsonDict")

               let loginURL = baseURL.baseURL + appEndPoints.login //+appEndPoints.login

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

                     if let resultData = dictData!["data"] as? [String:Any]{
                         print( resultData,"resultData")
                         let myStringVariable = (resultData["user_id"] as? String)

                     let myIntegerVariable = Int(myStringVariable!) ?? 0

                     let userid  = myIntegerVariable
                        print(userid,"userid in LoginVC"   )
                        UserDetail.shared.setUserId(String(myIntegerVariable))
                     let userid1 = UserDetail.shared.getUserId()
                     print(userid1, "user_id LogIN_VC")

                     self.showToast("Sign up successfully.")

                     DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
                         let vc = self.storyboard?.instantiateViewController(withIdentifier: "TabBarVC") as! TabBarVC
//                         vc.userid = String(userid)
//                         vc.emailphone = emailPhone_Txt.text

                     self.navigationController!.pushViewController(vc, animated: true)

                     }

                      // completionHandler("\(String(describing: dictData!["message"] as? String))", "")
                     } } else    {
                      // let responseMessage = dictData!["msg"] as! String
                       AlertController.alert(title: "", message: "Your email or password do not match. Please try again.")
                   }
                   //            hideHud()
               })
       
        

      
    }
    @IBAction func btnSignUp_Action(_ sender: Any) {
        print("SignUp Button Action")
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "SignUpVC") as! SignUpVC
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    @IBAction func btnForgotPassword_Action(_ sender: Any) {
        print("forgot Password Button Action")
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "RecoverPasswordVC") as! RecoverPasswordVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    func validateEmail(YourEMailAddress: String) -> Bool {
        let REGEX: String
        REGEX = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,3}"
        return NSPredicate(format: "SELF MATCHES %@", REGEX).evaluate(with: YourEMailAddress)
    }
    func validation() -> Bool {
        
        if txt_EmailPhone.text?.count == 0 {
            self.popupAlert(title: "Error", message: "Email can't be empty.", actionTitles: ["Ok"], actions:[{action1 in}])
            return false
        
        } else if txt_EmailPhone.text?.isNumeric == false {
            if  !validateEmail(YourEMailAddress: txt_EmailPhone.text!){
                self.popupAlert(title: "Error", message: "Please enter valid email.", actionTitles: ["Ok"], actions:[{action1 in}])
                return false
            }
            
        } else if txt_EmailPhone.text?.isNumeric == true || txt_EmailPhone.text!.count != 10 {
            if  !txt_EmailPhone.text!.isValidPhone(){
                self.popupAlert(title: "Error", message: "Please enter valid phone number.", actionTitles: ["Ok"], actions:[{action1 in}])
                return false
            }
        
    }
        if txt_Password.text?.count == 0 {
        self.popupAlert(title: "Error", message: "Password can't be empty.", actionTitles: ["Ok"], actions:[{action1 in}])
        return false
    }
      if !txt_Password.text!.isPasswordValid(){
            self.popupAlert(title: "Error", message: "Password should be minimum 8 characters. Atleast 1 Alphabet, 1 Special character and 1 Numeric value.", actionTitles: ["Ok"], actions:[{action1 in}])
            return false
          
        }
        
        return true
    }
    
}

extension String {
    
    var isNumeric: Bool {
        return !(self.isEmpty) && self.allSatisfy { $0.isNumber }
    }
    
//    func isValidEmail(_ email: String) -> Bool {
//        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,3}"
//
//        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
//        return emailPred.evaluate(with: email)
//    }
    
    func validateEmail(YourEMailAddress: String) -> Bool {
        let REGEX: String
        REGEX = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", REGEX).evaluate(with: YourEMailAddress)
    }
    func isValidEmail() -> Bool {

        let regex = try! NSRegularExpression(pattern: "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,3}", options: .caseInsensitive)
        return regex.firstMatch(in: self, options: [], range: NSRange(location: 0, length: count)) != nil
    }
    func isPasswordValid() -> Bool{
        if self.count >= 8 {
            return true
        }else{
            return false
        }
        //    let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{8,}$")
        //    return passwordTest.evaluate(with: self)
    }
    func isValidPhone() -> Bool {
        let phoneRegex = "^[0-9+]{0,1}+[0-9]{14,14}$"
        let phoneTest = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phoneTest.evaluate(with: self)
    }
}

extension UIViewController {
    func popupAlert(title: String?, message: String?, actionTitles:[String?], actions:[((UIAlertAction) -> Void)?]) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for (index, title) in actionTitles.enumerated() {
            let action = UIAlertAction(title: title, style: .default, handler: actions[index])
            alert.addAction(action)
        }
        self.present(alert, animated: true, completion: nil)
    }
}

extension LoginVC: UIScrollViewDelegate {

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
extension LoginVC {
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
//        var myMutableStringTitle = NSMutableAttributedString()
//            let Email  = "Enter Your Email/Phone" // PlaceHolderText

//            myMutableStringTitle = NSMutableAttributedString(string:Email, attributes: [NSFontAttributeName:UIFont(name: "System", size: 14.0)!]) // Font
//            myMutableStringTitle.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range:NSRange(location:0,length:Email.characters.count))    // Color
//            txt_EmailPhone.attributedPlaceholder = myMutableStringTitle
//        var yourImage = UIImage(named: "3x")
        // Set rendering mode to alwaysOriginal
//        yourImage = yourImage?.withRenderingMode(.alwaysOriginal)
//        self.upperCornerImg.image? = yourImage ?? UIImage()
        
        txt_EmailPhone.attributedPlaceholder = NSAttributedString(string:"Enter Your Email/Phone", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 40/255, green: 0, blue: 71/255, alpha: 1)])
        txt_Password.attributedPlaceholder = NSAttributedString(string:"Enter Your Email/Phone", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 40/255, green: 0, blue: 71/255, alpha: 1)])
    }
    private func darkModeEnabled() {
 //       var yourImage = UIImage(named: "3x")
        // Set rendering mode to alwaysOriginal
 //       yourImage = yourImage?.withRenderingMode(.alwaysTemplate)
//        self.upperCornerImg.tintColor = UIColor.black
//        self.upperCornerImg.image? = yourImage ?? UIImage()
        txt_EmailPhone.attributedPlaceholder = NSAttributedString(string:"Enter Your Email/Phone", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        txt_Password.attributedPlaceholder = NSAttributedString(string:"Password", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    }
}
