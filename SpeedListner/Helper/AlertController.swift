//
//  AlertController.swift
//  SpeedListners
//
//  Created by ravi on 14/12/22.
//


import UIKit

open class AlertController {
    
    // MARK: - Singleton
    
    static let instance = AlertController()
    
    // MARK: - Private Functions
    
    fileprivate func topMostController() -> UIViewController? {
        
        var presentedVC = UIApplication.shared.keyWindow?.rootViewController
        while let pVC = presentedVC?.presentedViewController {
            presentedVC = pVC
        }
        
        if presentedVC == nil {
            //print("AlertController Error: You don't have any views set. You may be calling in viewdidload. Try viewdidappear.")
        }
        return presentedVC
    }
    
    // MARK: - Class Functions
    
    open class func alert(title: String) {
        return alert(title: title, message: "")
    }
    
    open class func alert(message: String) {
        return alert(title: "", message: message)
    }
    
    open class func alert(title: String, message: String) {
        
        return alert(title: title, message: message, acceptMessage: "OK") { () -> () in
            // Do nothing
        }
    }
    
    open class func alert(title: String, message: String, acceptMessage: String, acceptBlock: @escaping () -> ()) {
        
        DispatchQueue.main.async(execute: {
            
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
            let acceptButton = UIAlertAction(title: acceptMessage, style: .default, handler: { (action: UIAlertAction) in
                acceptBlock()
            })
            
            alert.addAction(acceptButton)
            
            instance.topMostController()?.present(alert, animated: true, completion: nil)
            //return alert
        })
    }
    
    open class func alert(title: String, message: String, buttons:[String], tapBlock:((UIAlertAction,Int) -> Void)?) {
        
       
        DispatchQueue.main.async(execute: {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert, buttons: buttons, tapBlock: tapBlock)
           // alert.view.tintColor = RGBA(r: 39, g: 192, b: 146, a: 1)
            //alert.view.tintColor = RGBA(39, g: 192, b: 146, a: 1)
            instance.topMostController()?.present(alert, animated: true, completion: nil)
            //return alert
        })

    }
    
    open class func actionSheet(title: String, message: String, sourceView: UIView, actions: [UIAlertAction]) {
        
        DispatchQueue.main.async(execute: {
            let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.actionSheet)
            for action in actions {
                alert.addAction(action)
            }
            
            alert.popoverPresentationController?.sourceView = sourceView
            alert.popoverPresentationController?.sourceRect = sourceView.bounds
            instance.topMostController()?.present(alert, animated: true, completion: nil)
            //return alert
        })
    }
    
    open class func actionSheet(title: String, message: String, sourceView: UIView, buttons:[String], tapBlock:((UIAlertAction,Int) -> Void)?) {
        
        DispatchQueue.main.async(execute: {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet, buttons: buttons, tapBlock: tapBlock)
            alert.popoverPresentationController?.sourceView = sourceView
            alert.popoverPresentationController?.sourceRect = sourceView.bounds
            instance.topMostController()?.present(alert, animated: true, completion: nil)
            //return alert
        })
    }
    
}


private extension UIAlertController {
    convenience init(title: String?, message: String?, preferredStyle: UIAlertController.Style, buttons:[String], tapBlock:((UIAlertAction,Int) -> Void)?) {
        self.init(title: title, message: message, preferredStyle:preferredStyle)
        var buttonIndex = 0
        for buttonTitle in buttons {
            let action = UIAlertAction(title: buttonTitle, preferredStyle: .default, buttonIndex: buttonIndex, tapBlock: tapBlock)
            buttonIndex += 1
            //self.view.tintColor = UIColor.RGB(r: 33, g: 128, b: 188)
            self.addAction(action)
        }
    }
}

private extension UIAlertAction {
    convenience init(title: String?, preferredStyle: UIAlertAction.Style, buttonIndex:Int, tapBlock:((UIAlertAction,Int) -> Void)?) {
        self.init(title: title, style: preferredStyle) {
            (action:UIAlertAction) in
            if let block = tapBlock {
                block(action,buttonIndex)
            }
        }
    }
}
enum AlertMessages: String {
  
    case enterPassword = "Please enter old password"
    case passwordcount = "Password count must be between 6 to 15 characters"
    case validPassword = "Please enter a min. of 6 characters with an atleast 1 number and 1 alphabet"
    case newPassword = "Please enter new password"
    case confirmPassword = "Please enter confirm password"
    case passwordNotMatch = "Password does not match"

    
}

extension UIViewController{
    func showOkAlertWithHandler(_ msg: String, handler: @escaping ()->Void){
           let alert = UIAlertController(title: "", message: msg, preferredStyle: .alert)
           let okAction = UIAlertAction(title: "OK", style: .default) { (type) -> Void in
               handler()
           }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (type) -> Void in
          
        }
           alert.addAction(cancelAction)
           alert.addAction(okAction)
           present(alert, animated: true, completion: nil)
       }
}
