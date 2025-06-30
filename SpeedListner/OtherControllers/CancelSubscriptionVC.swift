//
//  CancelSubscriptionVC.swift
//  SpeedListners
// Created by ravi on 22/08/22.
//

import UIKit

class CancelSubscriptionVC: UIViewController,UITextViewDelegate {

    @IBOutlet weak var lblCountMessage: UILabel!
    @IBOutlet weak var txt_Message: UITextView!
    
    var cancelSub:()->() = {}
    
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
        txt_Message.delegate = self
        txt_Message.text = "Please Write Here..."
        //btnSave.backgroundColor = UIColor.gray
        txt_Message.textColor = UIColor.gray
        // Do any additional setup after loading the view.
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let words = txt_Message.text.components(separatedBy: .whitespacesAndNewlines)
        let filteredWords = words.filter({ (word) -> Bool in
            word != ""
        })
        let wordCount = filteredWords.count
        
        lblCountMessage.text = String(wordCount)
        print("chars \(wordCount) \( text)")

        if(wordCount > 99 && range.length == 0) {
            showAlert(for: "Please summarize in 100 words or less")
            print("Please summarize in 100 words or less")
            return false
        }
        return true
    }
    func textViewDidBeginEditing(_ textView: UITextView) {

        if txt_Message.textColor == UIColor.gray {
            txt_Message.text = ""
            txt_Message.textColor = UIColor.black
           // btnSave.backgroundColor =  #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1)
        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {

        if txt_Message.text == "" {
            txt_Message.textColor = UIColor.gray
            txt_Message.text = "Please Write Here..."
            txt_Message.textColor = UIColor.gray
           // btnSave.backgroundColor = UIColor.gray
           
        }
    }
    @IBAction func btnCancelSubscription_Action(_ sender: Any) {
        self.dismiss(animated: true) {
            self.cancelSub()
            self.view.removeFromSuperview()
           
        }
       
    }
    
    @IBAction func btnCross_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
   

}
// MARK: - Dark/Light Mode code
extension CancelSubscriptionVC {
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

//        txt_Message.attributedPlaceholder = NSAttributedString(string:"Enter Your Email/Phone", attributes: [NSAttributedStringKey.foregroundColor: UIColor(red: 40/255, green: 0, blue: 70/255, alpha: 1)])
       
    }
    private func darkModeEnabled() {
//        txt_Message.attributedPlaceholder = NSAttributedString(string:"Enter Your Email/Phone", attributes: [NSAttributedStringKey.foregroundColor: UIColor.white])
    
    }
}
