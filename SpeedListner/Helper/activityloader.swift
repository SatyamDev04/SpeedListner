//
//  activityloader.swift
//  SpeedListners
//
//  Created by ravi on 14/12/22.
//

import Foundation
import UIKit
import NVActivityIndicatorView

class indicator {
    var container: UIView = UIView()
    var loadingView: UIView = UIView()
    var activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView()
    func showActivityIndicator(uiView: UIView,Message:String = "Loading...") {
        container.frame = uiView.frame
        container.center = uiView.center
        container.frame.origin.y = 50
        let dev = UIDevice.current.name
        if dev == "iPhone X" || dev == "iPhone XS" || dev == "iPhone XS Max" || dev == "iPhone XR" {
            container.frame.origin.y = 80
        }
      //  container.backgroundColor = UIColor(red: 255/255, green: 255/255 , blue: 255/255, alpha: 0.2)
            //UIColorFromHex(rgbValue: 0x000000, alpha: 0.4)
        loadingView.frame = CGRect(x:0, y:0, width:160, height:120)
        loadingView.center = uiView.center
        loadingView.backgroundColor = UIColor(red:0/255, green: 23/255 , blue: 51/255, alpha: 1)
        loadingView.clipsToBounds = true
        loadingView.layer.cornerRadius = 10
        activityIndicator.frame = CGRect(x:0.0, y:0.0, width:40.0, height:40.0)
        activityIndicator.style = UIActivityIndicatorView.Style.whiteLarge
        activityIndicator.center = CGPoint(x:loadingView.frame.size.width / 2, y:(loadingView.frame.size.height / 2)-10);
        let messageLabel = UILabel(frame: CGRect(x:0.0, y:70, width:160, height:40.0))
        messageLabel.font = UIFont.boldSystemFont(ofSize: UIFont.labelFontSize)
        messageLabel.textColor = UIColor.white
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.text = Message
        loadingView.addSubview(activityIndicator)
        loadingView.addSubview(messageLabel)
        container.addSubview(loadingView)
        uiView.addSubview(container)
        activityIndicator.startAnimating()
    }
   // showActivityIndicator(uiView: UIView,Message:String = "Loading...")
    func hideActivityIndicator(uiView: UIView) {
        activityIndicator.stopAnimating()
        container.removeFromSuperview()
    }
    func UIColorFromHex(rgbValue:UInt32, alpha:Double=1.0)->UIColor {
        let red = CGFloat((rgbValue & 0xFF0000) >> 16)/256.0
        let green = CGFloat((rgbValue & 0xFF00) >> 8)/256.0
        let blue = CGFloat(rgbValue & 0xFF)/256.0
        return UIColor(red:red, green:green, blue:blue, alpha:CGFloat(alpha))
    }
    func showToast(message : String ,hightC:CGFloat = 35.0 ,viewC:UIView) {
        
        let toastLabel = UILabel(frame: CGRect(x: viewC.frame.size.width/2 - 75, y: viewC.frame.size.height-100, width: 150.0, height: hightC))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
//        toastLabel.font = UIFont(name: "Montserrat-Light", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        
        viewC.addSubview(toastLabel)
        UIView.animate(withDuration: 2.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    }
    
}

class LoadingView {
    var loadingView: UIView = UIView()
    var ActivityIndicator : NVActivityIndicatorView? = nil
    
    func showActivityLoading(uiView: UIView,type:NVActivityIndicatorType = .orbit,color : UIColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)) {
    
        ActivityIndicator = NVActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 60, height: 60), type: type, color: color, padding: nil)
        
        ActivityIndicator?.center = uiView.center
        ActivityIndicator?.tag = 1
        ActivityIndicator?.type = .ballRotateChase
        uiView.addSubview(ActivityIndicator!)
       ActivityIndicator?.startAnimating()
    }
    func ActivityShow() -> Bool {
        if ActivityIndicator?.tag == 1 {
            return false
        }
        return true
    }
    func hideActivityLoading(uiView: UIView?) {
        ActivityIndicator?.stopAnimating()
        ActivityIndicator?.tag = 2
        ActivityIndicator?.removeFromSuperview()
    }
    func loadErrorS(view:UIViewController,yPoition:CGFloat = 20, ViewC:UIView,image:UIImage = #imageLiteral(resourceName: "no_data_found") ,tintColor:UIColor = .white, Show:Bool,tag: Int = -1) {
        for ii in ViewC.subviews {
            if let d = ii as? UIImageView,d.tag == tag {
                ii.removeFromSuperview()
            }
        }
        if Show {
            let img = UIImageView()
            img.image = image
            img.frame.size = CGSize(width: 150, height: 150)
            img.tag = tag
//            img = view.p_loadErrorMessage()
            img.center = ViewC.center
            img.frame.origin.y = yPoition
            img.image = img.image?.withRenderingMode(.alwaysTemplate)
            img.tintColor = tintColor
            ViewC.addSubview(img)
        }
    }
}
extension UIViewController {
    func p_loadErrorMessage(size:CGSize = CGSize(width: 150, height: 150),img:UIImage = #imageLiteral(resourceName: "no_data_found"),tag:Int = 0) -> UIImageView {
        let button = UIImageView()
        button.image = img
        button.frame.size = size
        button.tag = tag
        return button
    }
}

extension UIViewController {
  
    func ShareControllerCuston(title:String?,videoId:String,completion: @escaping (_ dict:String) -> Void) {
        
        var obj : [Any] = []
        if let d = title {
            obj.append(d)
        }
        obj.append(#imageLiteral(resourceName: "logo"))
//        let firstActivityItem = "Justdance.linking1://videoId=\(videoId)"
        let firstActivityItem = "Justdance.linking1://videoId=\(videoId)"
        http://Justdance.linking1
        
        if let secondActivityItem = URL(string: firstActivityItem) {
            obj.append(secondActivityItem)
        }
//        let image : UIImage = #imageLiteral(resourceName: "logo")
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: obj, applicationActivities: nil)
        
        activityViewController.popoverPresentationController?.sourceView = self.view
        
        activityViewController.popoverPresentationController?.permittedArrowDirections = UIPopoverArrowDirection.any
        activityViewController.popoverPresentationController?.sourceRect = CGRect(x: 0, y: 0, width: 0, height: 0)
        self.present(activityViewController, animated: true, completion: nil)
        
    }
}
