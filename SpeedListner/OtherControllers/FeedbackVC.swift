//
//  FeedbackVC.swift
//  SpeedListners
//
//  Created by ravi on 24/08/22.
//

import UIKit

class FeedbackVC: UIViewController,UITextViewDelegate,DelegateforFeedbackPopUp {
    
    func MethodforPop() {
        if self.children.count > 0 {
            
            let viewControllers:[UIViewController] = self.children
            for viewContoller in viewControllers{
                self.tabBarController?.tabBar.isHidden = false
               //txt_ViewTxt.textColor = UIColor.lightGray
                txt_ViewTxt.text = ""
                if txt_ViewTxt.text == ""
                    {
                    txt_ViewTxt!.text = "Is There Anything We Can Improve?"
                    txt_ViewTxt!.textColor = UIColor.lightGray
                    }
                txt_ViewTxt.resignFirstResponder()
                self.btnAwesome.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1)
                self.btnGood.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 0.25)
                self.btnBad.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 0.25)
                self.btnOkay.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 0.25)
                self.btnAwesome.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
                self.btnGood.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
                self.btnBad.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
                self.btnOkay.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
                
                viewContoller.willMove(toParent: nil)
                viewContoller.view.removeFromSuperview()
                viewContoller.removeFromParent()
                self.navigationController?.popViewController(animated: true)
                }
            }
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    

    @IBOutlet weak var btnBad: UIButton!
    @IBOutlet weak var btnOkay: UIButton!
    @IBOutlet weak var btnGood: UIButton!
    @IBOutlet weak var btnAwesome: UIButton!
    @IBOutlet weak var txt_ViewTxt: UITextView!
    @IBOutlet weak var view_main: UIView!
    @IBOutlet weak var view_4TxtView: UIView!
    let loading = indicator()
    var lblPlaceHolder : UILabel!
    var feedbackname:String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.delegate = self
        txt_ViewTxt.delegate = self
        txt_ViewTxt.text = "Is There Anything We Can Improve?"
        txt_ViewTxt.textColor = UIColor.lightGray
        
        feedbackname = "Awesome"
        self.btnAwesome.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1)
        self.btnGood.backgroundColor = UIColor(named: "feedbackBg")
        self.btnBad.backgroundColor = UIColor(named: "feedbackBg")
        self.btnOkay.backgroundColor = UIColor(named: "feedbackBg")
        self.btnAwesome.setTitleColor(.white, for: .normal)
        self.btnGood.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
        self.btnBad.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
        self.btnOkay.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
        
        self.view_4TxtView.layer.borderWidth = 1
        self.view_4TxtView.layer.borderColor = UIColor.gray.cgColor
        self.view_main.layer.shadowColor = UIColor.gray.cgColor
        self.view_main.layer.shadowRadius = 15
        self.view_main.layer.shadowOpacity = 1.0
        self.view_main.layer.shadowOffset = .zero
        self.view_main.layer.masksToBounds = false
        
    }
    @IBAction func btnSubmit_Action(_ sender: Any) {
        
        let userid = UserDetail.shared.getUserId()
        let jsonDict : [String:Any] = ["user_id" :"\(userid)" ,"feedback_name" : feedbackname!,"feedback_description" : txt_ViewTxt.text!]
   
    print(jsonDict,"jsonDict")
    
        let loginURL = baseURL.baseURL + appEndPoints.feedback_user //+appEndPoints.create_password
    
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
          
          let vc: FeedbackPopupVC = self.storyboard?.instantiateViewController(withIdentifier: "FeedbackPopupVC") as! FeedbackPopupVC
          
         vc.delegateforfeedbackPopup = self
         
          self.addChild(vc)
          vc.view.frame = self.view.frame
          self.view.addSubview(vc.view)
          self.view.bringSubviewToFront(vc.view)
          vc.didMove(toParent: self)

           
        }  else    {

        }
     
    })
         
    }
    
    
    @IBAction func btnAwesome_Action(_ sender: Any) {
        
        feedbackname = "Awesome"
        self.btnAwesome.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1)
        self.btnGood.backgroundColor = UIColor(named: "feedbackBg")
        self.btnBad.backgroundColor = UIColor(named: "feedbackBg")
        self.btnOkay.backgroundColor = UIColor(named: "feedbackBg")
        self.btnAwesome.setTitleColor(.white, for: .normal)
        self.btnGood.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
        self.btnBad.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
        self.btnOkay.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
       
        
    }
    
    @IBAction func btnBad_Action(_ sender: Any) {
        feedbackname = "Bad"
        self.btnBad.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1)
        self.btnGood.backgroundColor = UIColor(named: "feedbackBg")
        self.btnAwesome.backgroundColor = UIColor(named: "feedbackBg")
        self.btnOkay.backgroundColor = UIColor(named: "feedbackBg")
        
        self.btnBad.setTitleColor(.white, for: .normal)
        self.btnGood.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
        self.btnAwesome.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
        self.btnOkay.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
    }
    
    @IBAction func btnGood_Action(_ sender: Any) {
        feedbackname = "Good"
        self.btnGood.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1)
        self.btnBad.backgroundColor = UIColor(named: "feedbackBg")
        self.btnAwesome.backgroundColor = UIColor(named: "feedbackBg")
        self.btnOkay.backgroundColor = UIColor(named: "feedbackBg")
        
        self.btnGood.setTitleColor(.white, for: .normal)
        self.btnBad.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
        self.btnAwesome.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
        self.btnOkay.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
        
        
    }
    
    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    
    @IBAction func btnOkay_Action(_ sender: Any) {
        feedbackname = "Okay"
        self.btnOkay.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1)
        self.btnBad.backgroundColor = UIColor(named: "feedbackBg")
        self.btnAwesome.backgroundColor = UIColor(named: "feedbackBg")
        self.btnGood.backgroundColor = UIColor(named: "feedbackBg")
        
        self.btnOkay.setTitleColor(.white, for: .normal)
        self.btnBad.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
        self.btnAwesome.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
        self.btnGood.setTitleColor(UIColor(named: "whitecolor"), for: .normal)
        
        
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {

        if (txt_ViewTxt.text == "Is There Anything We Can Improve?")

            {
            txt_ViewTxt!.text = ""
            txt_ViewTxt!.textColor = UIColor.black
            txt_ViewTxt.becomeFirstResponder()
            }
       
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {

        if txt_ViewTxt.text == ""
            {
            txt_ViewTxt!.text = "Is There Anything We Can Improve?"
            txt_ViewTxt!.textColor = UIColor.lightGray
            }
        txt_ViewTxt.resignFirstResponder()

    }
}

extension FeedbackVC: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
       
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
