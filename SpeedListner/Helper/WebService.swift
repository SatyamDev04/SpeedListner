//
//  WebService.swift
//  SpeedListners
//
//  Created by ravi on 14/12/22.
//
import Foundation
import Alamofire
import SwiftyJSON

class TokenManager {
    static let shared = TokenManager()
    private let tokenKey = "bearerToken"
    
    func saveToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    func getToken() -> String? {
        return UserDefaults.standard.string(forKey: tokenKey)
    }
    
    func removeToken() {
        UserDefaults.standard.removeObject(forKey: tokenKey)
    }
}
class LogoutManger:NSObject{
    
    static let shared = LogoutManger()
    
    func logout(){
       
        guard let topViewController = UIApplication.shared.windows.first?.rootViewController?.topmostViewController() else {
            print("Failed to find topmost view controller")
            return
        }
        topViewController.showOkAlertWithHandler("Account has been auto-logout due to Unaurhorised Access. Please login again to continue.") {
            let storyB = UIStoryboard(name: "Main", bundle: nil)
            
            let vc = storyB.instantiateViewController(withIdentifier: "LoginVC") as! LoginVC
            vc.hidesBottomBarWhenPushed = true
         
           UserDetail.shared.setPreviousUserId(UserDetail.shared.getUserId())
            print(UserDetail.shared.getUserId(),"onLogout",UserDetail.shared.getPreviousUserId())
            UserDetail.shared.setUserId("")
            UserDefaults.standard.set(0, forKey: "subs")
            topViewController.navigationController?.pushViewController(vc, animated: true)
        }
        
    }
}

class WebService {
    
    static let shared = WebService()
    
    private init() {
    }
    
    // Completion Handler
    typealias webServiceResponse = (JSON, Int) -> Void
    
    
    func postServiceURLEncoding(_ request: String, andParameter parameters: [String:Any]?, withCompletion completionHandler: @escaping webServiceResponse) {
        
        let reuestUrl =  request
        
        var encodingFormat: ParameterEncoding = URLEncoding()
        if request == "" {
            
//            encodingFormat = URLEncoding()
           encodingFormat = JSONEncoding()
        }
        
        let headers: HTTPHeaders = [
            "Authorization":"Bearer \(TokenManager.shared.getToken() ?? "")"
        ]
        AF.request(reuestUrl, method: .post, parameters: parameters, encoding: encodingFormat, headers: headers).responseJSON{ (responseData) in
            guard let statusCode = responseData.response?.statusCode else {return}
            if statusCode == 401  {
                self.showAlert(title: "", message: "Unauthorized")
                TokenManager.shared.removeToken()
                LogoutManger.shared.logout()
            }
            if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)") // original server data as UTF8 string
                do{
                    let statusCode = responseData.response?.statusCode
                    // Get json data
                    let json = try JSON(data: data)
                    print(json)
                    guard let dict = json.dictionaryObject else {return}
                    if let code = dict["code"] as? Int {
                        if code == 403 {
                            TokenManager.shared.removeToken()
                            LogoutManger.shared.logout()
                        }
                    }
                   // success(json, statusCode!)
                    if((responseData.result) != nil) {
                        let swiftyJsonData = responseData.result as? [String : Any]
                        completionHandler(json , statusCode!)
                    } else {
                       // // hideHud()
                        print(responseData.result)
                        completionHandler([:], statusCode!)
                    }
                }catch{
                    print("Unexpected error: \(error).")
                   // // hideHud()
                   // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                }
            }else{
              //  // hideHud()
               // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
            }
            
        }
    }
    
    func postService(_ request: String, andParameter parameters: [String:Any]?, withCompletion completionHandler: @escaping webServiceResponse) {
        
        let reuestUrl =  request
        
        var encodingFormat: ParameterEncoding =   JSONEncoding()  //URLEncoding()
        if request == "" {
            
   //encodingFormat = URLEncoding()
         encodingFormat = JSONEncoding()
        }
        
   
        let headers: HTTPHeaders = [
            "Accept": "application/json",
            "Authorization":"Bearer \(TokenManager.shared.getToken() ?? "")"
        ]
    
        AF.request(reuestUrl, method: .post, parameters: parameters, encoding: encodingFormat, headers: headers).responseJSON{ (responseData) in
            print(parameters, "parameters")
            print(headers, "headers")
            
            guard let statusCode = responseData.response?.statusCode else {return}
            if statusCode == 401  {
                self.showAlert(title: "", message: "Unauthorized")
                TokenManager.shared.removeToken()
                LogoutManger.shared.logout()
            }
            if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)") // original server data as UTF8 string
                do{
                    let statusCode = responseData.response?.statusCode
                    // Get json data
                    let json = try JSON(data: data)
                    print(json)
                    guard let dict = json.dictionaryObject else {return}
                    if let code = dict["code"] as? Int {
                        if code == 403 {
                            TokenManager.shared.removeToken()
                            LogoutManger.shared.logout()
                        }
                    }
                   // success(json, statusCode!)
                    if((responseData.result) != nil) {
                        let swiftyJsonData = responseData.result as? [String : Any]
                        completionHandler(json , statusCode!)
                    } else {
                       // // hideHud()
                        print(responseData.result)
                        completionHandler([:], statusCode!)
                    }
                }catch{
                    print("Unexpected error: \(error).")
                   // // hideHud()
                   // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                }
            }else{
              //  // hideHud()
               // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
            }
            
        }
    }
    func getServiceURLEncoding(_ request: String, andParameter parameters: [String:Any]?, withCompletion completionHandler: @escaping webServiceResponse) {
        
        let reuestUrl =  request
        
        var encodingFormat : ParameterEncoding = URLEncoding()
        if request == "" {
            
//            encodingFormat = JSONEncoding()

            encodingFormat = URLEncoding()
        }
        
        let headers: HTTPHeaders = [
            "Authorization":"Bearer \(TokenManager.shared.getToken() ?? "")",
           "Content-Type": "application/x-www-form-urlencoded"
        ]
        AF.request(reuestUrl,
        method: .get,
        encoding: encodingFormat,
                   headers: headers).responseJSON{ (responseData) in
            guard let statusCode = responseData.response?.statusCode else {return}
            if statusCode == 401  {
                self.showAlert(title: "", message: "Unauthorized")
                TokenManager.shared.removeToken()
                LogoutManger.shared.logout()
            }
            if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)") // original server data as UTF8 string
                do{
                    let statusCode = responseData.response?.statusCode
                    // Get json data
                    let json = try JSON(data: data)
                    print(json)
                    guard let dict = json.dictionaryObject else {return}
                    if let code = dict["code"] as? Int {
                        if code == 403 {
                            TokenManager.shared.removeToken()
                            LogoutManger.shared.logout()
                        }
                    }
                   // success(json, statusCode!)
                    if((responseData.result) != nil) {
                        let swiftyJsonData = responseData.result as? [String : Any]
                        completionHandler(json, statusCode!)
                    } else {
                        // hideHud()
                        print(responseData.result)
                        completionHandler([:], statusCode!)
                    }
                }catch{
                    // hideHud()
                    print("Unexpected error: \(error).")
                   // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                }
            }else{
                // hideHud()
               // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
            }
            
            /*
            if responseData.result.isSuccess {
                if((responseData.result.value) != nil) {
                    let swiftyJsonData = responseData.result.value as? [String : Any]
                    completionHandler(swiftyJsonData! , nil)
                } else {
                    print(responseData.result)
                }
            } else {
                completionHandler([:], responseData.error)
            }
            */
        }
    }
    
    
    
    func getService(_ request: String, andParameter parameters: [String:Any]?, withCompletion completionHandler: @escaping webServiceResponse) {
        
        let reuestUrl =  request
        
        var encodingFormat : ParameterEncoding = URLEncoding.default
        if request == "" {
            encodingFormat = URLEncoding()
        }
        
        let headers: HTTPHeaders = [
            "Authorization":"Bearer \(TokenManager.shared.getToken() ?? "")",
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        //AF.request(...).responseDecodable(of: YourType.self,
   // emptyResponseCodes: [200, 204, 205]) { response in
        
        AF.request(reuestUrl,
        method: .get,
                   encoding: encodingFormat,
                   headers: headers).validate()
            .responseData(emptyResponseCodes: [200, 204, 205,404]) { responseData in
                guard let statusCode = responseData.response?.statusCode else {return}
                if statusCode == 401  {
                    self.showAlert(title: "", message: "Unauthorized")
                    TokenManager.shared.removeToken()
                    LogoutManger.shared.logout()
                }
//        AF.request(reuestUrl,
//        method: .get,
//        encoding: URLEncoding.default,
//        headers: [:]).responseJSON{ (responseData) in
            
            if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)") // original server data as UTF8 string
                do{
                    let statusCode = responseData.response?.statusCode
                    // Get json data
                    let json = try JSON(data: data)
                    print(json)
                    guard let dict = json.dictionaryObject else {return}
                    if let code = dict["code"] as? Int {
                        if code == 403 {
                            TokenManager.shared.removeToken()
                            LogoutManger.shared.logout()
                        }
                    }
                   // success(json, statusCode!)
                    if((responseData.result) != nil) {
                        let swiftyJsonData = responseData.result as? [String : Any]
                        completionHandler(json, statusCode!)
                    } else {
                        // hideHud()
                        print(responseData.result)
                        completionHandler([:], statusCode!)
                    }
                }catch{
                    // hideHud()
                    print("Unexpected error: \(error).")
                   // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                }
            }else{
                // hideHud()
               // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
            }
            
            /*
            if responseData.result.isSuccess {
                if((responseData.result.value) != nil) {
                    let swiftyJsonData = responseData.result.value as? [String : Any]
                    completionHandler(swiftyJsonData! , nil)
                } else {
                    print(responseData.result)
                }
            } else {
                completionHandler([:], responseData.error)
            }
            */
        }
    }
    
    func uploadImageWithParameterWithTwoImage(_ request: String,_ image:Data?,_ image2:[Data]?, parameters: [String:Any]?,imageName:String,imageName1:String, withCompletion completionHandler: @escaping webServiceResponse) {
            
            let reuestUrl = request
            let headers: HTTPHeaders = [
                "Authorization":"Bearer \(TokenManager.shared.getToken() ?? "")"
            ]
        
        AF.upload(multipartFormData: { multiPart in
            if let allParams = parameters as? [String:String] {
                for (key, value) in allParams {
                    multiPart.append(value.data(using: .utf8)!, withName: key)
                  
                }
            }
            
            
            if let imgExist = image {
                let name = NSUUID().uuidString.lowercased()

                multiPart.append(imgExist, withName: imageName, fileName: "\(name).png", mimeType: "image/png")

            }
//            if let imgExist = image {
//                let name = NSUUID().uuidString.lowercased()
//                multiPart.append(imgExist, withName: imageName, fileName: "\(name).jpeg", mimeType: "image/jpeg")
//
//            }
            
            for i in 0..<image2!.count{

//            }

//            if let imgExist = image2 {
                let name = NSUUID().uuidString.lowercased()
                multiPart.append(image2![i], withName: "imageOrVideo[]", fileName: "imageOrVideo.png", mimeType: "image/png")
                
               // multiPart.append(image2[i], withName: imageName1, fileName: "\(name).jpeg", mimeType: "image/jpeg")

            }
            
        }, to: request, method: .post, headers: headers).uploadProgress(queue: .main, closure: { progress in
                    //Current upload progress of file
                    print("Upload Progress: \(progress.fractionCompleted)")
                
                })
                .responseJSON(completionHandler: { responseData in
                    guard let statusCode = responseData.response?.statusCode else {return}
                    if statusCode == 401  {
                        self.showAlert(title: "", message: "Unauthorized")
                        TokenManager.shared.removeToken()
                        LogoutManger.shared.logout()
                    }
                print(responseData)
                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
                        guard let dict = json.dictionaryObject else {return}
                        if let code = dict["code"] as? Int {
                            if code == 403 {
                                TokenManager.shared.removeToken()
                                LogoutManger.shared.logout()
                            }
                        }
                        if((responseData.result) != nil) {
                            let swiftyJsonData = responseData.result as? [String : Any]
                            completionHandler(json , statusCode!)
                        } else {
                            print(responseData.result)
                            completionHandler([:], statusCode!)
                        }
                    }catch{
                        
                        print("Unexpected error: \(error).")
                      
                    }
                }else{
              
                }
            })
    }
    
    
    
    func uploadImageWithParameterXY(_ request: String,_ image:Data?,_ image2:[Data], parameters: [String:Any]?,imageName:String,imageName1:String, withCompletion completionHandler: @escaping webServiceResponse) {

            let reuestUrl = request
            let headers: HTTPHeaders = [
                "Authorization":"Bearer \(TokenManager.shared.getToken() ?? "")"
            ]

        AF.upload(multipartFormData: { multiPart in
            if let allParams = parameters as? [String:String] {
                for (key, value) in allParams {
                    multiPart.append(value.data(using: .utf8)!, withName: key)
                    //multiPart.append(value.data(using: .utf8)!, withName: key)
                }
            }

            if let imgExist = image {
                let name = NSUUID().uuidString.lowercased()

                multiPart.append(imgExist, withName: imageName, fileName: "\(name).jpeg", mimeType: "image/jpeg")

            }

            for i in 0..<image2.count{

//            }

//            if let imgExist = image2 {
                let name = NSUUID().uuidString.lowercased()
                multiPart.append(image2[i], withName: "imageOrVideo[]", fileName: "imageOrVideo.png", mimeType: "image/png")
                
               // multiPart.append(image2[i], withName: imageName1, fileName: "\(name).jpeg", mimeType: "image/jpeg")

            }
//            if let imgExist = image3 {
//                let name = NSUUID().uuidString.lowercased()
//                multiPart.append(imgExist, withName: imageName2, fileName: "\(name).jpeg", mimeType: "image/jpeg")
//
//            }

        }, to: request, method: .post, headers: headers).uploadProgress(queue: .main, closure: { progress in
                    //Current upload progress of file
                    print("Upload Progress: \(progress.fractionCompleted)")

                })
                .responseJSON(completionHandler: { responseData in
                    guard let statusCode = responseData.response?.statusCode else {return}
                    if statusCode == 401  {
                        self.showAlert(title: "", message: "Unauthorized")
                        TokenManager.shared.removeToken()
                        LogoutManger.shared.logout()
                    }
                print(responseData)
                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
                        guard let dict = json.dictionaryObject else {return}
                        if let code = dict["code"] as? Int {
                            if code == 403 {
                                TokenManager.shared.removeToken()
                                LogoutManger.shared.logout()
                            }
                        }
                       // success(json, statusCode!)
                        if((responseData.result) != nil) {
                            let swiftyJsonData = responseData.result as? [String : Any]
                            completionHandler(json , statusCode!)
                        } else {
                             //hideHud()
                            print(responseData.result)
                            completionHandler([:], statusCode!)
                        }
                    }catch{
                        // hideHud()
                        print("Unexpected error: \(error).")
                       // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                    }
                }else{
                    // hideHud()
                   // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                }
            })
    }
    
    
    
    func uploadImageWithParameter(_ request: String,_ image:Data?,_ image2:[Data],_ image3:Data?, parameters: [String:Any]?,imageName:String,imageName1:String,imageName2:String, withCompletion completionHandler: @escaping webServiceResponse) {

            let reuestUrl = request
            let headers: HTTPHeaders = [
                "Authorization":"Bearer \(TokenManager.shared.getToken() ?? "")"
            ]

        AF.upload(multipartFormData: { multiPart in
            if let allParams = parameters as? [String:String] {
                for (key, value) in allParams {
                    multiPart.append(value.data(using: .utf8)!, withName: key)
                    //multiPart.append(value.data(using: .utf8)!, withName: key)
                }
            }

            if let imgExist = image {
                let name = NSUUID().uuidString.lowercased()

                multiPart.append(imgExist, withName: imageName, fileName: "\(name).jpeg", mimeType: "image/jpeg")

            }

            for i in 0..<image2.count{

//            }

//            if let imgExist = image2 {
                let name = NSUUID().uuidString.lowercased()
                multiPart.append(image2[i], withName: "imageOrVideo[]", fileName: "imageOrVideo.png", mimeType: "image/png")
                
               // multiPart.append(image2[i], withName: imageName1, fileName: "\(name).jpeg", mimeType: "image/jpeg")

            }
            if let imgExist = image3 {
                let name = NSUUID().uuidString.lowercased()
                multiPart.append(imgExist, withName: imageName2, fileName: "\(name).jpeg", mimeType: "image/jpeg")

            }

        }, to: request, method: .post, headers: headers).uploadProgress(queue: .main, closure: { progress in
                    //Current upload progress of file
                    print("Upload Progress: \(progress.fractionCompleted)")

                })
                .responseJSON(completionHandler: { responseData in
                    guard let statusCode = responseData.response?.statusCode else {return}
                    if statusCode == 401  {
                        self.showAlert(title: "", message: "Unauthorized")
                        TokenManager.shared.removeToken()
                        LogoutManger.shared.logout()
                    }
                    print(responseData)
                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
                        guard let dict = json.dictionaryObject else {return}
                        if let code = dict["code"] as? Int {
                            if code == 403 {
                                TokenManager.shared.removeToken()
                                LogoutManger.shared.logout()
                            }
                        }
                       // success(json, statusCode!)
                        if((responseData.result) != nil) {
                            let swiftyJsonData = responseData.result as? [String : Any]
                            completionHandler(json , statusCode!)
                        } else {
                             //hideHud()
                            print(responseData.result)
                            completionHandler([:], statusCode!)
                        }
                    }catch{
                        // hideHud()
                        print("Unexpected error: \(error).")
                       // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                    }
                }else{
                    // hideHud()
                   // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                }
            })
    }
    
    func uploadImageWithParameter(_ request: String,_ image:Data?,_ image2:Data?,_ image3:Data?, parameters: [String:Any]?,imageName:String,imageName1:String,imageName2:String, withCompletion completionHandler: @escaping webServiceResponse) {

            let reuestUrl = request
            let headers: HTTPHeaders = [
                "Authorization":"Bearer \(TokenManager.shared.getToken() ?? "")"
            ]

        AF.upload(multipartFormData: { multiPart in
            if let allParams = parameters as? [String:String] {
                for (key, value) in allParams {
                    multiPart.append(value.data(using: .utf8)!, withName: key)
                    //multiPart.append(value.data(using: .utf8)!, withName: key)
                }
            }

            if let imgExist = image {
                let name = NSUUID().uuidString.lowercased()

                multiPart.append(imgExist, withName: imageName, fileName: "\(name).jpeg", mimeType: "image/jpeg")

            }

            //for i in 0..<image2.count{

//            }

            if let imgExist = image2  {
                let name = NSUUID().uuidString.lowercased()
                multiPart.append(imgExist, withName: imageName1, fileName: "\(name).jpeg", mimeType: "image/jpeg")

            }
            if let imgExist = image3 {
                let name = NSUUID().uuidString.lowercased()
                multiPart.append(imgExist, withName: imageName2, fileName: "\(name).jpeg", mimeType: "image/jpeg")

            }

        }, to: request, method: .post, headers: headers).uploadProgress(queue: .main, closure: { progress in
                    //Current upload progress of file
                    print("Upload Progress: \(progress.fractionCompleted)")

                })
                .responseJSON(completionHandler: { responseData in
                    guard let statusCode = responseData.response?.statusCode else {return}
                    if statusCode == 401  {
                        self.showAlert(title: "", message: "Unauthorized")
                        TokenManager.shared.removeToken()
                        LogoutManger.shared.logout()
                    }
                print(responseData)
                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
                        guard let dict = json.dictionaryObject else {return}
                        if let code = dict["code"] as? Int {
                            if code == 403 {
                                TokenManager.shared.removeToken()
                                LogoutManger.shared.logout()
                            }
                        }
                       // success(json, statusCode!)
                        if((responseData.result) != nil) {
                            let swiftyJsonData = responseData.result as? [String : Any]
                            completionHandler(json , statusCode!)
                        } else {
                             //hideHud()
                            print(responseData.result)
                            completionHandler([:], statusCode!)
                        }
                    }catch{
                        // hideHud()
                        print("Unexpected error: \(error).")
                       // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                    }
                }else{
                    // hideHud()
                   // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                }
            })
    }
    func uploadImageWithParameter(_ request: String,_ image:[Data]?,_ parameters: [String:Any]?,imageName:String, withCompletion completionHandler: @escaping webServiceResponse) {
            
            let reuestUrl = request
            let headers: HTTPHeaders = [
                "Authorization":"Bearer \(TokenManager.shared.getToken() ?? "")"
            ]
        
        AF.upload(multipartFormData: { multiPart in
            if let allParams = parameters as? [String:String] {
                for (key, value) in allParams {
                    multiPart.append(value.data(using: .utf8)!, withName: key)
                }
            }
            for i in 0..<image!.count{
            if let imgExist = image {
                let name = NSUUID().uuidString.lowercased()
//                imageOrVideo[]
               // "morephoto[\(i)]", fileName: "photo\(i).jpeg" , mimeType: "image/jpeg")

                multiPart.append(imgExist[i], withName: "imageOrVideo[]", fileName: "imageOrVideo.png", mimeType: "image/png")
                //multiPart.append(imgExist[i], withName: imageName, fileName: "\(name).png", mimeType: "image/jpeg")
               // multiPart.append(imgExist, withName: imageName1, fileName: "\(name).jpeg", mimeType: "image/jpeg")

            } }
            
        }, to: request, method: .post, headers: headers).uploadProgress(queue: .main, closure: { progress in
                    //Current upload progress of file
                    print("Upload Progress: \(progress.fractionCompleted)")
                
                })
                .responseJSON(completionHandler: { responseData in
                    guard let statusCode = responseData.response?.statusCode else {return}
                    if statusCode == 401  {
                        self.showAlert(title: "", message: "Unauthorized")
                        TokenManager.shared.removeToken()
                        LogoutManger.shared.logout()
                    }
                print(responseData)
                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
                        guard let dict = json.dictionaryObject else {return}
                        if let code = dict["code"] as? Int {
                            if code == 403 {
                                TokenManager.shared.removeToken()
                                LogoutManger.shared.logout()
                            }
                        }
                       // success(json, statusCode!)
                        if((responseData.result) != nil) {
                            let swiftyJsonData = responseData.result as? [String : Any]
                            completionHandler(json , statusCode!)
                        } else {
                             //hideHud()
                            print(responseData.result)
                            completionHandler([:], statusCode!)
                        }
                    }catch{
                        // hideHud()
                        print("Unexpected error: \(error).")
                       // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                    }
                }else{
                    // hideHud()
                   // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                }
            })
    }
    
    
    func uploadImageWithParameterVedio1(_ request: String,_ image:Data?,Attachment: Data?,_ parameters: [String:Any]?,imageName:String,imageName2:String, withCompletion completionHandler: @escaping webServiceResponse) {
            
            let reuestUrl = request
            let headers: HTTPHeaders = [
                "Authorization":"Bearer \(TokenManager.shared.getToken() ?? "")"
            ]
        
        AF.upload(multipartFormData: { multiPart in
            if let allParams = parameters as? [String:String] {
                for (key, value) in allParams {
                    multiPart.append(value.data(using: .utf8)!, withName: key)
                }
            }
            if image!.count > 0 {
//                if Attachment!.count > 0  {
//                   let imageName1 = "thumble_img"
//                }
            if let imgExist = image {
                let name = NSUUID().uuidString.lowercased()
                multiPart.append(imgExist, withName: imageName, fileName: "\(name).jpeg", mimeType: "image/jpeg")
               // multiPart.append(imgExist, withName: imageName1, fileName: "\(name).jpeg", mimeType: "image/jpeg")
            }
                if let imgExist = image {
                    let name = NSUUID().uuidString.lowercased()
                    multiPart.append(imgExist, withName: imageName2, fileName: "\(name).jpeg", mimeType: "image/jpeg")
                   // multiPart.append(imgExist, withName: imageName1, fileName: "\(name).jpeg", mimeType: "image/jpeg")
                }
            }
            if Attachment!.count > 0  {
            if let imgExist = Attachment {
            //   let FileType1 = self.FileType.sharedInstance.FileType
                
                let name = NSUUID().uuidString.lowercased()
                multiPart.append(imgExist, withName: imageName, fileName: "\(name).mp4", mimeType: "mov/mp4")

            } }
            
//            if let imgExist = image
//                let name = NSUUID().uuidString.lowercased()
//                multiPart.append(imgExist, withName: imageName, fileName: "\(name).mp4", mimeType: "mov/mp4")
//               // multiPart.append(imgExist, withName: imageName1, fileName: "\(name).jpeg", mimeType: "image/jpeg")
//
//            }

            
        }, to: request, method: .post, headers: headers).uploadProgress(queue: .main, closure: { progress in
                    //Current upload progress of file
                    print("Upload Progress: \(progress.fractionCompleted)")
                
                })
                .responseJSON(completionHandler: { responseData in
                    guard let statusCode = responseData.response?.statusCode else {return}
                    if statusCode == 401  {
                        self.showAlert(title: "", message: "Unauthorized")
                        TokenManager.shared.removeToken()
                        LogoutManger.shared.logout()
                    }
                print(responseData)
                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
                        guard let dict = json.dictionaryObject else {return}
                        if let code = dict["code"] as? Int {
                            if code == 403 {
                                TokenManager.shared.removeToken()
                                LogoutManger.shared.logout()
                            }
                        }
                       // success(json, statusCode!)
                        if((responseData.result) != nil) {
                            let swiftyJsonData = responseData.result as? [String : Any]
                            completionHandler(json , statusCode!)
                        } else {
                             //hideHud()
                            print(responseData.result)
                            completionHandler([:], statusCode!)
                        }
                    }catch{
                        // hideHud()
                        print("Unexpected error: \(error).")
                       // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                    }
                }else{
                    // hideHud()
                   // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                }
            })
    }

    func uploadImageWithParameter(_ request: String,_ image:Data?,_ parameters: [String:Any]?,imageName:String, withCompletion completionHandler: @escaping webServiceResponse) {
            
            let reuestUrl = request
            let headers: HTTPHeaders = [
                "Authorization":"Bearer \(TokenManager.shared.getToken() ?? "")"
            ]
        
        AF.upload(multipartFormData: { multiPart in
            if let allParams = parameters as? [String:String] {
                for (key, value) in allParams {
                    multiPart.append(value.data(using: .utf8)!, withName: key)
                }
            }
            
            if let imgExist = image {
                let name = NSUUID().uuidString.lowercased()
                multiPart.append(imgExist, withName: imageName, fileName: "\(name).jpeg", mimeType: "image/jpeg")
                print((imgExist, withName: imageName, fileName: "\(name).jpeg", mimeType: "image/jpeg"))
               // multiPart.append(imgExist, withName: imageName1, fileName: "\(name).jpeg", mimeType: "image/jpeg")

            }
            


            
        }, to: request, method: .post, headers: headers).uploadProgress(queue: .main, closure: { progress in
                    //Current upload progress of file
                    print("Upload Progress: \(progress.fractionCompleted)")
                
                })
                .responseJSON(completionHandler: { responseData in
                    guard let statusCode = responseData.response?.statusCode else {return}
                    if statusCode == 401  {
                        self.showAlert(title: "", message: "Unauthorized")
                        TokenManager.shared.removeToken()
                        LogoutManger.shared.logout()
                    }
                print(responseData)
                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
                        guard let dict = json.dictionaryObject else {return}
                        if let code = dict["code"] as? Int {
                            if code == 403 {
                                TokenManager.shared.removeToken()
                                LogoutManger.shared.logout()
                            }
                        }
                       // success(json, statusCode!)
                        if((responseData.result) != nil) {
                            let swiftyJsonData = responseData.result as? [String : Any]
                            completionHandler(json , statusCode!)
                        } else {
                             //hideHud()
                            print(responseData.result)
                            completionHandler([:], statusCode!)
                        }
                    }catch{
                        // hideHud()
                        print("Unexpected error: \(error).")
                       // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                    }
                }else{
                   
                }
            })
    }
    
    func uploadCertificateImageWithParameter(_ request: String,_ imageMbbs:Data?,_ imageMCI:Data?,_ parameters: [String:Any]?,mbbsCertName:String,mciCertName:String, withCompletion completionHandler: @escaping webServiceResponse) {
            
            let reuestUrl = request
            let headers: HTTPHeaders = [
                "Authorization":"Bearer \(TokenManager.shared.getToken() ?? "")"
            ]
        
        AF.upload(multipartFormData: { multiPart in
            if let allParams = parameters as? [String:String] {
                for (key, value) in allParams {
                    multiPart.append(value.data(using: .utf8)!, withName: key)
                }
            }
            
            if let imgExist = imageMCI {
                let name = NSUUID().uuidString.lowercased()
                multiPart.append(imgExist, withName: mciCertName, fileName: "\(name).jpeg", mimeType: "image/jpeg")
            }
            
            if let imgExist = imageMbbs {
                let name = NSUUID().uuidString.lowercased()
                multiPart.append(imgExist, withName: mbbsCertName, fileName: "\(name).jpeg", mimeType: "image/jpeg")
            }
            
            
        }, to: request, method: .post, headers: headers).uploadProgress(queue: .main, closure: { progress in
                    //Current upload progress of file
                    print("Upload Progress: \(progress.fractionCompleted)")
                })
                .responseJSON(completionHandler: { responseData in
                    guard let statusCode = responseData.response?.statusCode else {return}
                    if statusCode == 401  {
                      self.showAlert(title: "", message: "Unauthorized")
                      TokenManager.shared.removeToken()
                      LogoutManger.shared.logout()
                      
                    }
                print(responseData)
                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
                        guard let dict = json.dictionaryObject else {return}
                        if let code = dict["code"] as? Int {
                            if code == 403 {
                                TokenManager.shared.removeToken()
                                LogoutManger.shared.logout()
                            }
                        }
                       // success(json, statusCode!)
                        if((responseData.result) != nil) {
                            let swiftyJsonData = responseData.result as? [String : Any]
                            completionHandler(json , statusCode!)
                        } else {
                            // hideHud()
                            print(responseData.result)
                            completionHandler([:], statusCode!)
                        }
                    }catch{
                       
                        print("Unexpected error: \(error).")
                       
                    }
                }else{
                   
                }
            })
        
    }
    
    
    func uploadAttachmentImageWithParameter(_ request: String,_ originalImage:Data?,_ thumbnailImage:Data?,_ parameters: [String:Any]?, withCompletion completionHandler: @escaping webServiceResponse) {
            
            let reuestUrl = request
            let headers: HTTPHeaders = [
                "Authorization":"Bearer \(TokenManager.shared.getToken() ?? "")"
            ]
        
        AF.upload(multipartFormData: { multiPart in
            if let allParams = parameters as? [String:String] {
                for (key, value) in allParams {
                    multiPart.append(value.data(using: .utf8)!, withName: key)
                }
            }
            
            if let imgExist = originalImage {
                let name = NSUUID().uuidString.lowercased()
                multiPart.append(imgExist, withName: "orginalFile", fileName: "\(name).jpeg", mimeType: "image/jpeg")
            }
            
            if let imgExist = thumbnailImage {
                let name = NSUUID().uuidString.lowercased()
                multiPart.append(imgExist, withName: "thumbnails", fileName: "\(name).jpeg", mimeType: "image/jpeg")
            }
            
            
        }, to: request, method: .post, headers: headers).uploadProgress(queue: .main, closure: { progress in
                    //Current upload progress of file
                    print("Upload Progress: \(progress.fractionCompleted)")
                })
                .responseJSON(completionHandler: { responseData in
                   
                    guard let statusCode = responseData.response?.statusCode else {return}
                    if statusCode == 401  {
                      self.showAlert(title: "", message: "Unauthorized")
                      TokenManager.shared.removeToken()
                      LogoutManger.shared.logout()
                      
                    }
                print(responseData)
                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
                        guard let dict = json.dictionaryObject else {return}
                        if let code = dict["code"] as? Int {
                            if code == 403 {
                                TokenManager.shared.removeToken()
                                LogoutManger.shared.logout()
                            }
                        }
                       // success(json, statusCode!)
                        if((responseData.result) != nil) {
                            let swiftyJsonData = responseData.result as? [String : Any]
                            completionHandler(json , statusCode!)
                        } else {
                            print(responseData.result)
                            completionHandler([:], statusCode!)
                        }
                    }catch{
                        print("Unexpected error: \(error).")
                        self.showAlert(title: "", message: "Sever Error")
                       // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                    }
                }else{
                    self.showAlert(title: "", message: "Sever Error")
                   // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                }
            })
        
       
    }
    
    
    func servicePostWithFoamDataParameter(
        _ request: String,
        _ parameters: [String: Any]?,
        withCompletion completionHandler: @escaping webServiceResponse
    ) {
        let headers: HTTPHeaders = [
            "Authorization": "Bearer \(TokenManager.shared.getToken() ?? "")",
            "Content-Type": "application/json"
        ]

        AF.upload(multipartFormData: { multiPart in
            if let allParams = parameters {
                for (key, value) in allParams {
                    // Safely convert value to Data
                    if let stringValue = "\(value)".data(using: .utf8) {
                        multiPart.append(stringValue, withName: key)
                    }
                }
            }
        }, to: request, method: .post, headers: headers)
        .uploadProgress(queue: .main) { progress in
            print("Upload Progress: \(progress.fractionCompleted)")
        }
        .responseData { response in
            guard let statusCode = response.response?.statusCode else {return}
            print(response.response?.statusCode ?? 0,"statusCode from postman" )
            if statusCode == 401  {
              self.showAlert(title: "", message: "Unauthorized")
              TokenManager.shared.removeToken()
              LogoutManger.shared.logout()
              
            }
            switch response.result {
            case .success(let data):
                if let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)")
                }

                do {
                    let json = try JSON(data: data)
                    print("JSON:", json)
                    let statusCode = response.response?.statusCode ?? 0
                    if let dict = json.dictionaryObject,
                       let code = dict["code"] as? Int,
                       code == 403 || statusCode == 401  {
                        self.showAlert(title: "", message: "Unauthorized")
                        TokenManager.shared.removeToken()
                        LogoutManger.shared.logout()
                        
                    }
                    completionHandler(json,statusCode)
                 
                } catch {
                    self.showAlert(title: "", message: "Sever Error")
                    print("JSON Parsing Error:", error.localizedDescription)
                //    completionHandler(JSON([:]), statusCode)
                }

            case .failure(let error):
                print("Network or Parsing Error:", error.localizedDescription)
                self.showAlert(title: "", message: "Sever Error")
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        guard let topViewController = getTopViewController() else { return }
      
        DispatchQueue.main.async {
            topViewController.showToast(message)
        }
    }

    private func getTopViewController(base: UIViewController? = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController) -> UIViewController? {
        if let navController = base as? UINavigationController {
            return getTopViewController(base: navController.visibleViewController)
        } else if let tabBarController = base as? UITabBarController,
                  let selected = tabBarController.selectedViewController {
            return getTopViewController(base: selected)
        } else if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
}
