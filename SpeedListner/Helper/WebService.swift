//
//  WebService.swift
//  SpeedListners
//
//  Created by ravi on 14/12/22.
//
import Foundation
import Alamofire
import SwiftyJSON


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
//            "Accept": "application/json",
//            "Authorization":""
        ]
        
        AF.request(reuestUrl, method: .post, parameters: parameters, encoding: encodingFormat, headers: headers).responseJSON{ (responseData) in
            
            if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)") // original server data as UTF8 string
                do{
                    let statusCode = responseData.response?.statusCode
                    // Get json data
                    let json = try JSON(data: data)
                    print(json)
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
//            "Authorization":""
        ]
       //print(parameters, "parameters")
        AF.request(reuestUrl, method: .post, parameters: parameters, encoding: encodingFormat, headers: headers).responseJSON{ (responseData) in
            print(parameters, "parameters")
            print(headers, "headers")
            if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)") // original server data as UTF8 string
                do{
                    let statusCode = responseData.response?.statusCode
                    // Get json data
                    let json = try JSON(data: data)
                    print(json)
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
            //"Content-Type": "application/json"
           "Content-Type": "application/x-www-form-urlencoded"
        ]
        AF.request(reuestUrl,
        method: .get,
        encoding: encodingFormat,
        headers: [:]).responseJSON{ (responseData) in
            
            if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                print("Data: \(utf8Text)") // original server data as UTF8 string
                do{
                    let statusCode = responseData.response?.statusCode
                    // Get json data
                    let json = try JSON(data: data)
                    print(json)
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
            //"Content-Type": "application/json"
            "Content-Type": "application/x-www-form-urlencoded"
        ]
        
        //AF.request(...).responseDecodable(of: YourType.self,
   // emptyResponseCodes: [200, 204, 205]) { response in
        
        AF.request(reuestUrl,
        method: .get,
                   encoding: encodingFormat,
                   headers: [:]).validate()
            .responseData(emptyResponseCodes: [200, 204, 205,404]) { responseData in
                
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
               // "Authorization":"Basic bml0aW50eWFnaTpwYXNzd29yZEAxMjM="
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
            
        }, to: request, method: .post, headers: nil).uploadProgress(queue: .main, closure: { progress in
                    //Current upload progress of file
                    print("Upload Progress: \(progress.fractionCompleted)")
                
                })
                .responseJSON(completionHandler: { responseData in
                //Do what ever you want to do with response
                print(responseData)
                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
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
    
    
    
    func uploadImageWithParameterXY(_ request: String,_ image:Data?,_ image2:[Data], parameters: [String:Any]?,imageName:String,imageName1:String, withCompletion completionHandler: @escaping webServiceResponse) {

            let reuestUrl = request
            let headers: HTTPHeaders = [
               // "Authorization":"Basic bml0aW50eWFnaTpwYXNzd29yZEAxMjM="
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

        }, to: request, method: .post, headers: nil).uploadProgress(queue: .main, closure: { progress in
                    //Current upload progress of file
                    print("Upload Progress: \(progress.fractionCompleted)")

                })
                .responseJSON(completionHandler: { responseData in
                //Do what ever you want to do with response
                print(responseData)
                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
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
               // "Authorization":"Basic bml0aW50eWFnaTpwYXNzd29yZEAxMjM="
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

        }, to: request, method: .post, headers: nil).uploadProgress(queue: .main, closure: { progress in
                    //Current upload progress of file
                    print("Upload Progress: \(progress.fractionCompleted)")

                })
                .responseJSON(completionHandler: { responseData in
                //Do what ever you want to do with response
                print(responseData)
                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
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
               // "Authorization":"Basic bml0aW50eWFnaTpwYXNzd29yZEAxMjM="
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

        }, to: request, method: .post, headers: nil).uploadProgress(queue: .main, closure: { progress in
                    //Current upload progress of file
                    print("Upload Progress: \(progress.fractionCompleted)")

                })
                .responseJSON(completionHandler: { responseData in
                //Do what ever you want to do with response
                print(responseData)
                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
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
               // "Authorization":"Basic bml0aW50eWFnaTpwYXNzd29yZEAxMjM="
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
            
        }, to: request, method: .post, headers: nil).uploadProgress(queue: .main, closure: { progress in
                    //Current upload progress of file
                    print("Upload Progress: \(progress.fractionCompleted)")
                
                })
                .responseJSON(completionHandler: { responseData in
                //Do what ever you want to do with response
                print(responseData)
                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
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
    
   // let FileType = FileTypeClass1()
    func uploadImageWithParameterVedio1(_ request: String,_ image:Data?,Attachment: Data?,_ parameters: [String:Any]?,imageName:String, withCompletion completionHandler: @escaping webServiceResponse) {
            
            let reuestUrl = request
            let headers: HTTPHeaders = [
               // "Authorization":"Basic bml0aW50eWFnaTpwYXNzd29yZEAxMjM="
            ]
        
        AF.upload(multipartFormData: { multiPart in
            if let allParams = parameters as? [String:String] {
                for (key, value) in allParams {
                    multiPart.append(value.data(using: .utf8)!, withName: key)
                }
            }
            if image!.count > 0 {
            if let imgExist = image {
                let name = NSUUID().uuidString.lowercased()
                multiPart.append(imgExist, withName: imageName, fileName: "\(name).jpeg", mimeType: "image/jpeg")
               // multiPart.append(imgExist, withName: imageName1, fileName: "\(name).jpeg", mimeType: "image/jpeg")
            }
            }
//            if Attachment!.count > 0  {
//            if let imgExist = Attachment {
//               let FileType1 = self.FileType.sharedInstance.FileType
//
//                let name = NSUUID().uuidString.lowercased()
//                multiPart.append(imgExist, withName: imageName, fileName: "\(name).mp4", mimeType: "mov/mp4")
//
//            }
//
//            }
            
//            if let imgExist = image
//                let name = NSUUID().uuidString.lowercased()
//                multiPart.append(imgExist, withName: imageName, fileName: "\(name).mp4", mimeType: "mov/mp4")
//               // multiPart.append(imgExist, withName: imageName1, fileName: "\(name).jpeg", mimeType: "image/jpeg")
//
//            }

            
        }, to: request, method: .post, headers: nil).uploadProgress(queue: .main, closure: { progress in
                    //Current upload progress of file
                    print("Upload Progress: \(progress.fractionCompleted)")
                
                })
                .responseJSON(completionHandler: { responseData in
                //Do what ever you want to do with response
                print(responseData)
                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
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
               // "Authorization":"Basic bml0aW50eWFnaTpwYXNzd29yZEAxMjM="
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
               // multiPart.append(imgExist, withName: imageName1, fileName: "\(name).jpeg", mimeType: "image/jpeg")

            }
            
//            if let imgExist = image {
//                let name = NSUUID().uuidString.lowercased()
//                multiPart.append(imgExist, withName: imageName, fileName: "\(name).mp4", mimeType: "mov/mp4")
//               // multiPart.append(imgExist, withName: imageName1, fileName: "\(name).jpeg", mimeType: "image/jpeg")
//
//            }

            
        }, to: request, method: .post, headers: nil).uploadProgress(queue: .main, closure: { progress in
                    //Current upload progress of file
                    print("Upload Progress: \(progress.fractionCompleted)")
                
                })
                .responseJSON(completionHandler: { responseData in
                //Do what ever you want to do with response
                print(responseData)
                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
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
    
    
    
    
//    func uploadImageWithParameter(_ request: String,_ image:Data?,_ parameters: [String:Any]?,imageName:String, withCompletion completionHandler: @escaping webServiceResponse) {
//
//            let reuestUrl = request
//            let headers: HTTPHeaders = [
//               // "Authorization":"Basic bml0aW50eWFnaTpwYXNzd29yZEAxMjM="
//            ]
//
//        AF.upload(multipartFormData: { multiPart in
//            if let allParams = parameters as? [String:String] {
//                for (key, value) in allParams {
//                    multiPart.append(value.data(using: .utf8)!, withName: key)
//                }
//            }
//
//            if let imgExist = image {
//                let name = NSUUID().uuidString.lowercased()
//                multiPart.append(imgExist, withName: imageName, fileName: "\(name).jpeg", mimeType: "image/jpeg")
//               // multiPart.append(imgExist, withName: imageName1, fileName: "\(name).jpeg", mimeType: "image/jpeg")
//
//            }
//
//        }, to: request, method: .post, headers: nil).uploadProgress(queue: .main, closure: { progress in
//                    //Current upload progress of file
//                    print("Upload Progress: \(progress.fractionCompleted)")
//
//                })
//                .responseJSON(completionHandler: { responseData in
//                //Do what ever you want to do with response
//                print(responseData)
//                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
//                    print("Data: \(utf8Text)") // original server data as UTF8 string
//                    do{
//                        let statusCode = responseData.response?.statusCode
//                        // Get json data
//                        let json = try JSON(data: data)
//                        print(json)
//                       // success(json, statusCode!)
//                        if((responseData.result) != nil) {
//                            let swiftyJsonData = responseData.result as? [String : Any]
//                            completionHandler(json , statusCode!)
//                        } else {
//                             //hideHud()
//                            print(responseData.result)
//                            completionHandler([:], statusCode!)
//                        }
//                    }catch{
//                        // hideHud()
//                        print("Unexpected error: \(error).")
//                       // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
//                    }
//                }else{
//                    // hideHud()
//                   // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
//                }
//            })
//    }
    func uploadCertificateImageWithParameter(_ request: String,_ imageMbbs:Data?,_ imageMCI:Data?,_ parameters: [String:Any]?,mbbsCertName:String,mciCertName:String, withCompletion completionHandler: @escaping webServiceResponse) {
            
            let reuestUrl = request
            let headers: HTTPHeaders = [
                "Authorization":"Basic bml0aW50eWFnaTpwYXNzd29yZEAxMjM=",
                "Content-Type":"multipart/form-data"
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
                //Do what ever you want to do with response
                print(responseData)
                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
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
    
    
    func uploadAttachmentImageWithParameter(_ request: String,_ originalImage:Data?,_ thumbnailImage:Data?,_ parameters: [String:Any]?, withCompletion completionHandler: @escaping webServiceResponse) {
            
            let reuestUrl = request
            let headers: HTTPHeaders = [
//                "Authorization":"Basic bml0aW50eWFnaTpwYXNzd29yZEAxMjM="
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
                //Do what ever you want to do with response
                print(responseData)
                if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
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
                       // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                    }
                }else{
                   // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                }
            })
        
       
    }
    
    
    func servicePostWithFoamDataParameter(_ request: String,_ parameters: [String:Any]?, withCompletion completionHandler: @escaping webServiceResponse) {
            
            let reuestUrl = request
            let headers: HTTPHeaders = [
                //"Content-Type": "application/x-www-form-urlencoded"
             // "Authorization":"Basic bml0aW50eWFnaTpwYXNzd29yZEAxMjM="
            ]
        
        AF.upload(multipartFormData: { multiPart in
            if let allParams = parameters as? [String:String] {
                for (key, value) in allParams {
                    multiPart.append(value.data(using: .utf8)!, withName: key)
                }
            }
            
        }, to: request, method: .post, headers: headers).uploadProgress(queue: .main, closure: { progress in
                    //Current upload progress of file
                    print("Upload Progress: \(progress.fractionCompleted)")
                })
                .responseJSON(completionHandler: { responseData in
                //Do what ever you want to do with response
                print(responseData)
                    if let data = responseData.data, let utf8Text = String(data: data, encoding: .utf8) {
                    print("Data: \(utf8Text)") // original server data as UTF8 string
                    do{
                        let statusCode = responseData.response?.statusCode
                        // Get json data
                        let json = try JSON(data: data)
                        print(json)
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
                       // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                    }
                }else{
                   // alertUser(strTitle: "Message", strMessage: "  Could not connect to the server.")
                }
            })
        
    }
    
    
//    public func RequestApiMultipleImages(url:String,imageParamKey:String, arrayImageData:NSMutableArray, parameters:Parameters,isHeaderIncluded:Bool, headers:HTTPHeaders, completion: @escaping (_ result: DataResponse<Any>) -> Void) {
//
//       if(isHeaderIncluded) {
//        Alamofire.upload(multipartFormData: { multipartFormData in
//            // import image to request
//            for imageData in arrayImageData {
//                multipartFormData.append(imageData  as! Data, withName: imageParamKey+"[]", fileName: "\(Date().timeIntervalSince1970).jpeg", mimeType: "image/jpeg")
//            }
//
//            for (key, value) in parameters {
//                multipartFormData.append((value as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
//            }
//       }, to:url,headers:headers)
//       {
//            (result) in
//            switch result {
//            case .success(let upload,_,_ ):
//                upload.uploadProgress(closure: { (progress) in
//                    //Print progress
//                    print(progress)
//                })
//                //To check and verify server error
//                /*upload.responseString(completionHandler: { (response) in
//                 print(response)
//                 print (response.result)
//                 })*/
//                upload.responseJSON
//                    { response in
//
//                        switch response.result {
//                        case .success:
//                            print(response)
//                            completion(response)
//                            break
//                        case .failure(let error):
//                            print(error)
//                            completion(response)
//                     }
//                }
//
//            case .failure(_):
//                print(result)
//                // completion(responds)
//            }
//        }
//        }
//        else
//       {
//        Alamofire.upload(multipartFormData: { multipartFormData in
//            // import image to request
//            for imageData in arrayImageData {
//                multipartFormData.append(imageData  as! Data, withName: imageParamKey+"[]", fileName: "\(Date().timeIntervalSince1970).jpeg", mimeType: "image/jpeg")
//            }
//
//            for (key, value) in parameters {
//                multipartFormData.append((value as AnyObject).data(using: String.Encoding.utf8.rawValue)!, withName: key)
//            }
//        }, to:url)
//        {
//            (result) in
//            switch result {
//            case .success(let upload,_,_ ):
//                upload.uploadProgress(closure: { (progress) in
//                    //Print progress
//                    print(progress)
//                })
//                //To check and verify server error
//                /*upload.responseString(completionHandler: { (response) in
//                 print(response)
//                 print (response.result)
//                 })*/
//                upload.responseJSON
//                    { response in
//
//                        switch response.result {
//                        case .success:
//                            print(response)
//                            completion(response)
//                            break
//                        case .failure(let error):
//                            print(error)
//                            completion(response)
//                        }
//                }
//
//            case .failure(_):
//                print(result)
//                // completion(responds)
//            }
//        }
//        }
//    }
    
   
    
    /*
    func getAppleMusicPlaylist(_ request: String, token : String, developerToken :String, andParameter parameters: [String:Any]?, withCompletion completionHandler: @escaping webServiceResponse) {
        
        let reuestUrl =  "https://api.music.apple.com/v1/me/library/playlists"
        
        var encodingFormat: ParameterEncoding = JSONEncoding()
        if request == "" {
            encodingFormat = URLEncoding()
        }
        
        let headers: HTTPHeaders = [
            "Accept": "application/json",
            "Content-Type":"application/json",
            "Authorization":"Bearer \(token)","Music-User-Token":developerToken
        ]
        AF.request(reuestUrl, method: .get, parameters: parameters, encoding: URLEncoding.queryString, headers: headers).responseJSON{ (responseData) in
            
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
        }
    }
    
    func getAppleMusicSongDetails(_ request: String, token : String, developerToken :String,storeFrontId:String, songId:String ,andParameter parameters: [String:Any]?, withCompletion completionHandler: @escaping webServiceResponse) {
        
        let reuestUrl =  "https://api.music.apple.com/v1/catalog/\(storeFrontId)/songs/\(songId)"
        
        var encodingFormat: ParameterEncoding = JSONEncoding()
        if request == "" {
            encodingFormat = URLEncoding()
        }
        
        let headers: HTTPHeaders = [
            "Accept": "application/json",
            "Content-Type":"application/json",
            "Authorization":"Bearer \(token)","Music-User-Token":developerToken
        ]
        Alamofire.request(reuestUrl, method: .get, parameters: parameters, encoding: URLEncoding.queryString, headers: headers).responseJSON{ (responseData) in
            
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
        }
    }
    
    func getSpotifyService(_ request: String, token : String, andParameter parameters: [String:Any]?, withCompletion completionHandler: @escaping webServiceResponse) {
        
        let reuestUrl =  request
        
        var encodingFormat: ParameterEncoding = JSONEncoding()
        if request == "" {
            encodingFormat = URLEncoding()
        }
        
        let headers: HTTPHeaders = [
            "Accept": "application/json",
            "Content-Type":"application/json",
            "Authorization":"Bearer \(token)"
        ]
        Alamofire.request(reuestUrl, method: .get, parameters: parameters, encoding: URLEncoding.queryString, headers: headers).responseJSON{ (responseData) in
            
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
        }
    }
    
    func postSpotifyService(_ request: String, token : String, andParameter parameters: [String:Any]?, withCompletion completionHandler: @escaping webServiceResponse) {
        
        let reuestUrl =  request
        
        var encodingFormat: ParameterEncoding = JSONEncoding()
        if request == "" {
            encodingFormat = JSONEncoding() //URLEncoding()
        }
        
        let headers: HTTPHeaders = [
            "Content-Type":"application/json",
            "Authorization":"Bearer \(token)"
        ]
        Alamofire.request(reuestUrl, method: .post, parameters: parameters!, encoding: encodingFormat, headers: headers).responseJSON{ (responseData) in
            
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
        }
    }
    
    func putSpotifyService(_ request: String, token : String, andParameter parameters: [String:Any], withCompletion completionHandler: @escaping webServiceResponse) {
        
        let reuestUrl =  request
        /*
        let headers = [
            "Content-Type":"image/jpeg",
            "Authorization":"Bearer \(token)",
            "Cache-Control": "no-cache"
        ]
        
        let postData = parameters.data(using: String.Encoding.utf8) // NSData(data: parameters.data(using: String.Encoding.utf8)!)
        
        let request = NSMutableURLRequest(url: NSURL(string: request)! as URL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 10.0)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = headers
        request.httpBody = postData
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            
            //            if response.result.isSuccess {
            //                if((response.result.value) != nil) {
            //                    let swiftyJsonData = response.result.value as? [String : Any]
            //                    completionHandler(swiftyJsonData! , nil)
            //                } else {
            //                    print(response.result)
            //                }
            //            } else {
            //                completionHandler([:], response.error)
            //            }
            
            if (error != nil) {
                print(error)
            } else {
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse)
            }
        })
        
        dataTask.resume()
        
        */
        
                var encodingFormat: ParameterEncoding = URLEncoding()
                if request == "" {
                    encodingFormat = JSONEncoding() //URLEncoding()  ParameterEncoding()
                }
        
                let headers: HTTPHeaders = [
                    "Content-Type":"image/jpeg",
                    "Authorization":"Bearer \(token)",
                    "scope" : "playlist-modify-public"
                ]
        Alamofire.request(reuestUrl, method: .put, parameters: parameters, encoding:encodingFormat , headers: headers).responseJSON{ (responseData) in
        
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
                }
    }
    
    func callGetService(urlString:String, withCompletion completionHandler: @escaping webServiceResponse)  {
        
        let url = URL(string: urlString)
        
        Alamofire.request(url!).validate()
            .responseJSON { (responseData) in
                
                if responseData.result.isSuccess {
                    if((responseData.result.value) != nil) {
                        let swiftyJsonData = responseData.result.value as? [String : Any]
                        completionHandler(swiftyJsonData!, nil)
                    } else {
                        print(responseData.result)
                    }
                } else {
                    completionHandler([:], responseData.error)
                }
        }
    }
    
    
    func uploadImageWithParameter(_ request: String,_ image:Data?,_ parameters: [String:Any]?, withCompletion getResponse: @escaping webServiceResponse) {
        
        let reuestUrl = request
//        let headers: HTTPHeaders = [
//            /* "Authorization": "your_access_token",  in case you need authorization header */
//            "Content-type": "multipart/form-data"
//        ]
        Alamofire.upload(multipartFormData: { multipartFormData in
            if let imgExist = image {
                let name = NSUUID().uuidString.lowercased()
                multipartFormData.append(imgExist, withName: "avatar", fileName: "\(name).jpeg", mimeType: "image/jpeg")
            }
            
            if let allParams = parameters as? [String:String] {
                for (key, value) in allParams {
                    multipartFormData.append(value.data(using: .utf8)!, withName: key)
                }
            }}, to: reuestUrl, method: .post, headers:nil,
                encodingCompletion: { encodingResult in
                    switch encodingResult {
                    case .success(let upload, _, _):
                        
                        upload.responseJSON { response in
                            guard response.result.error == nil else {
                                print("error response")
                                print(response.result.error ?? "error response")
                                getResponse([:],response.result.error)
                                
                                return
                            }
                            if let value = response.result.value {
                                print(value)
                                getResponse(value as! [String : Any],nil)
                            }
                        }
                    case .failure(let encodingError):
                        print("error:\(encodingError)")
                        getResponse([:], encodingError)
                    }
        })
    }
    
    func uploadVoiceRecording_ImageWithParameter(_ request: String,_ image:Data?, _ recordingUrl : URL?,_ imageName : String,_ parameters: [String:Any]?, withCompletion getResponse: @escaping webServiceResponse) {
        
        let reuestUrl = request
        let headers: HTTPHeaders = [
            /* "Authorization": "your_access_token",  in case you need authorization header */
            "Content-type": "multipart/form-data"
        ]
        
        
        Alamofire.upload(multipartFormData: { multipartFormData in
            
            
            if let allParams = parameters as? [String:String] {
                for (key, value) in allParams {
                    multipartFormData.append(value.data(using: .utf8)!, withName: key)
                }
            }
            if recordingUrl != nil{
                multipartFormData.append(recordingUrl!, withName: "voiceRecording")
            }
            
            if let imgExist = image {
                let name = NSUUID().uuidString.lowercased()
                if imageName == "profileImg"{
                    multipartFormData.append(imgExist, withName: "profileImg", fileName: "\(name).jpeg", mimeType: "image/jpeg")
                }else{
                    multipartFormData.append(imgExist, withName: "artworkImage", fileName: "\(name).jpeg", mimeType: "image/jpeg")
                }
            }
            
        }, to: reuestUrl, method: .post, headers:nil,
                encodingCompletion: { encodingResult in
                    switch encodingResult {
                    case .success(let upload, _, _):
                        
                        upload.responseJSON { response in
                            guard response.result.error == nil else {
                                print("error response")
                                print(response.result.error ?? "error response")
                                getResponse([:],response.result.error)
                                
                                return
                            }
                            if let value = response.result.value {
                                print(value)
                                getResponse(value as! [String : Any],nil)
                            }
                        }
                    case .failure(let encodingError):
                        print("error:\(encodingError)")
                        getResponse([:], encodingError)
                    }
        })
    }
    */
}


