//
//  PLRBsdkVC.swift
//  TripAndFall
//
//  Created by Anubhav on 23/06/22.
//  Copyright © 2022 Ankur&Pavan. All rights reserved.
//


import UIKit
import WebKit

protocol Afterpay {
    func afterPayData(paymentDetails:[String:Any])
}

class PLRBsdkVC: UIViewController,WKNavigationDelegate,WKUIDelegate {
    
    @IBOutlet weak var CustomView: UIView!
    var url = ""
    var Id = ""
    var loading = LoadingView()
    var timer = Timer()
    var delegate:Afterpay?
    var loginData = [String:Any]()
    var timerClose = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clearCache()
        let url = URL(string: self.url)
        let request = URLRequest(url: url!)
        let webView = WKWebView(frame: self.CustomView.frame)
        webView.autoresizingMask = [.flexibleWidth, .flexibleHeight] //It assigns Custom View height and width
        webView.navigationDelegate = self
        
        webView.load(request)
        self.CustomView.addSubview(webView)
      

    
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }

       
        
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
//        self.timer.invalidate()
    }
    
    @IBAction func doneBtn(_ sender: Any) {
//        self.timerClose = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.dismiss(animated: true, completion: nil)
        }
      
    }
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
//        self.loading.showActivityLoading(uiView: webView)
    }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print(webView.url ?? URL(fileURLWithPath: ""))
        //        clearCache()
        if let url = webView.url?.absoluteString{
            if url == "https://speedlistener.yesitlabs.co/payment_test"{
                DispatchQueue.main.asyncAfter(deadline: .now() + 0) {
                    self.dismiss(animated: true) {
                        self.delegate?.afterPayData(paymentDetails: [:])
                    }
                }
            }
            
        }
    }
    func clearCache() {
        removeCookies()
        if #available(iOS 9.0, *) {
            let websiteDataTypes = NSSet(array: [WKWebsiteDataTypeDiskCache, WKWebsiteDataTypeMemoryCache])
            let date = NSDate(timeIntervalSince1970: 0)
            WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes as! Set<String>, modifiedSince: date as Date, completionHandler:{ })
        } else {
            var libraryPath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, false).first!
            libraryPath += "/Cookies"

            do {
                try FileManager.default.removeItem(atPath: libraryPath)
            } catch {
                print("error")
            }
            URLCache.shared.removeAllCachedResponses()
        }
    }
    func removeCookies() {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        print("All cookies deleted")

        WKWebsiteDataStore.default().fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
            records.forEach { record in
                WKWebsiteDataStore.default().removeData(ofTypes: record.dataTypes, for: [record], completionHandler: {})
                print("Cookie ::: \(record) deleted")
            }
        }
    }
}
    extension WKWebView {
        func evaluate(script: String, completion: @escaping (Any?, Error?) -> Void) {
            var finished = false

            evaluateJavaScript(script, completionHandler: { (result, error) in
                if error == nil {
                    if result != nil {
                        completion(result, nil)
                    }
                } else {
                    completion(nil, error)
                }
                finished = true
            })

            while !finished {
                RunLoop.current.run(mode: RunLoop.Mode(rawValue: "NSDefaultRunLoopMode"), before: NSDate.distantFuture)
            }
        }
    }

extension String {

    func stripOutHtml() -> String? {
        do {
            guard let data = self.data(using: .unicode) else {
                return nil
            }
            let attributed = try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil)
            return attributed.string
        } catch {
            return nil
        }
    }

}
