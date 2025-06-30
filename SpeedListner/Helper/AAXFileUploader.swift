//
//  DocumentUploader.swift
//  My Air Spa
//
//  Created by YATIN  KALRA on 02/08/24.
//



import UIKit
import Alamofire
import SwiftyJSON

class UploadDoc: NSObject {

    var progressRing: RAProgressRing?
    var backgroundView: UIView?
    var topViewController: UIViewController?
    var downloadProgressBar: UIProgressView?
    var loading = indicator()
    
    
    override init() {
        super.init()
        setupProgressRing()
        setupDownloadProgressBar()
    }
    
    
    private func setupProgressRing() {
        guard let topViewController = UIApplication.shared.windows.first?.rootViewController?.topmostViewController() else {
            print("Failed to find topmost view controller")
            return
        }
        self.topViewController = topViewController
        
        if backgroundView == nil {
            backgroundView = createBackgroundView()
            topViewController.view?.addSubview(backgroundView ?? UIView())
        } else {
            backgroundView?.isHidden = false
        }
        
        if progressRing == nil {
            progressRing = createProgressRing()
            topViewController.view?.addSubview(progressRing ?? UIView())
        } else {
            progressRing?.progress = 0
            progressRing?.isHidden = false
        }
    }
    
    
    private func createBackgroundView() -> UIView {
        let backgroundView = UIView(frame: CGRect(x: 0, y: 0, width: 120, height: 120))
        backgroundView.backgroundColor = .white
        backgroundView.layer.cornerRadius = 60
        backgroundView.center = topViewController?.view.center ?? .zero
        return backgroundView
    }
    
    
    private func createProgressRing() -> RAProgressRing {
        let progressRing = RAProgressRing(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        progressRing.trackColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1).withAlphaComponent(0.25)
        progressRing.circleColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1)
        progressRing.center = topViewController?.view.center ?? .zero
        return progressRing
    }
    
    private func setupDownloadProgressBar() {
        if downloadProgressBar == nil {
            downloadProgressBar = UIProgressView(progressViewStyle: .default)
            downloadProgressBar?.progress = 0
            downloadProgressBar?.trackTintColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1).withAlphaComponent(0.25)
            downloadProgressBar?.progressTintColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1)
            downloadProgressBar?.frame = CGRect(x: 20, y: (topViewController?.view.frame.height ?? 0) - 100, width: (topViewController?.view.frame.width ?? 0) - 40, height: 20)
            
            topViewController?.view.addSubview(downloadProgressBar!)
        }
        downloadProgressBar?.isHidden = true
    }
    
    private func hideProgressRing() {
        self.topViewController?.view.isUserInteractionEnabled = true
        self.backgroundView?.isHidden = true
        self.progressRing?.isHidden = true
        self.progressRing = nil
        self.backgroundView = nil
    }
    private func hideDownloadProgressBar() {
        self.topViewController?.view.isUserInteractionEnabled = true
        self.downloadProgressBar?.isHidden = true
        self.downloadProgressBar = nil
        
    }
    func upload(parameters: [[String: Any]], to urlString: String, progress: @escaping (Double) -> Void, completion: @escaping (Result<Any, Error>) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(.failure(URLError(.badURL)))
            return
        }

        setupProgressRing()

        AF.upload(multipartFormData: { multipartFormData in
            for param in parameters {
                let paramName = param["key"] as! String
                let paramType = param["type"] as! String
                
                if paramType == "file" {
                    let paramSrc = param["src"] as! URL
                    let fileURL =  paramSrc
                    multipartFormData.append(fileURL, withName: paramName, fileName: fileURL.lastPathComponent, mimeType: "application/octet-stream")
                }
            }
        }, to: url, method: .post, headers: ["Content-Type": "multipart/form-data"])
        .uploadProgress { progressData in
            DispatchQueue.main.async {
                self.topViewController?.view.isUserInteractionEnabled = false
                self.backgroundView?.isHidden = false
                self.progressRing?.isHidden = false
                
                progress(progressData.fractionCompleted)
                self.progressRing?.progress = CGFloat(progressData.fractionCompleted)
            }
        }
        .response { response in
            DispatchQueue.main.async {
                self.hideProgressRing()

                if let error = response.error {
                    print("Upload Failure: \(error.localizedDescription)")
                    completion(.failure(error))
                } else if let data = response.data {
                    print("Upload Success: \(String(data: data, encoding: .utf8) ?? "No data")")
                    completion(.success(data))
                } else {
                    print("Unknown Error")
                    completion(.failure(URLError(.unknown)))
                }
            }
        }
    }
    
    
    func startUpload(parameters: [[String: Any]], completion: @escaping (Result<Bool,Error>) -> Void) {
        guard let topViewController = UIApplication.shared.windows.first?.rootViewController?.topmostViewController() else {
            print("Failed to find topmost view controller")
            return
        }

        let uploadURL = "http://18.218.153.204/convert/"

        self.upload(parameters: parameters, to: uploadURL, progress: { percentage in
            print("Upload Progress: \(percentage * 100)%")
            if (percentage * 100) == 100.0{
             //   self.topViewController?.showToast("Start Dycrpting,process will take time Please wait.")
                self.hideProgressRing()
                self.loading.showActivityIndicator(uiView: topViewController.view,Message: "Dycrpting...")
            }
        }) { result in
            switch result {
            case .success(let value):
                let jsonResponse = JSON(value)
                if let dict = jsonResponse.dictionaryObject, let status = dict["status"] as? Bool, status == true,let convertedFileUrl = dict["file_url"] as? String {
                    
                  //  topViewController.showToast("File converted successfully.")
                    self.startFileDownloadAndSaveToLibrary(from: convertedFileUrl) { success in
                        if success == true{
                            topViewController.showToast("File downloaded successfully")
                        }else{
                            topViewController.showToast("File downloading Failed")
                        }
                        completion(.success(success))
                            
                    }

                    self.loading.hideActivityIndicator(uiView: topViewController.view)
                    self.hideProgressRing()
                    
                } else {
                    let message = jsonResponse.dictionaryObject?["message"] as? String ?? "Error"
                    topViewController.showToast(message)
                    completion(.success(false))
                }
                
            case .failure(let error):
                print("Upload Failure: \(error.localizedDescription)")
                topViewController.showToast("Upload failed: \(error.localizedDescription)")
                completion(.failure(error))
            }
        }
    }
    func downloadFile(from url: String, completion: @escaping (URL?) -> Void) {
           guard let downloadURL = URL(string: url) else {
               completion(nil)
               return
           }
        
        //self.topViewController?.showToast("Start downloading,Please wait.")
           let destination: DownloadRequest.Destination = { _, _ in
               let documentsURL = NewDataMannagerClass.getProcessedFolderURL()
               let fileURL = documentsURL.appendingPathComponent(downloadURL.lastPathComponent)
               return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
           }

        

           AF.download(downloadURL, to: destination)
               .downloadProgress { progressData in
                   DispatchQueue.main.async {
                       self.downloadProgressBar?.progress = Float(progressData.fractionCompleted)
                   }
               }
               .responseData { response in
                   self.hideProgressRing()
                   self.hideDownloadProgressBar()
                   switch response.result {
                   case .success:
                       if let filePath = response.fileURL {
                           print("Download successful: \(filePath.path)")
                           completion(filePath)
                       } else {
                           print("File download failed.")
                           completion(nil)
                       }
                   case .failure(let error):
                       print("Download failure: \(error.localizedDescription)")
                       completion(nil)
                   }
               }
       }

       func startFileDownloadAndSaveToLibrary(from url: String, completion: @escaping (Bool) -> Void) {
           self.downloadProgressBar?.isHidden = false
           downloadFile(from: url) { fileURL in
               guard let downloadedFileURL = fileURL else {
                   completion(false)
                   return
               }
               
               let library = NewDataMannagerClass.getLibrary()
               let bookURL = BookURL(original: downloadedFileURL, processed: downloadedFileURL)
               
               NewDataMannagerClass.insertBooks(from: [bookURL], into: nil, or: library) {
                   print("File added to library successfully.")
                   NewDataMannagerClass.saveContext()
                   completion(true)
                   
               }
           }
       }
}
extension UIViewController {
    func topmostViewController() -> UIViewController {
        if let presentedViewController = presentedViewController {
            return presentedViewController.topmostViewController()
        }
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topmostViewController() ?? navigationController
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topmostViewController() ?? tabBarController
        }
        return self
    }
}
