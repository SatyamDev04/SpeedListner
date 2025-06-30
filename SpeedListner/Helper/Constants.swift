//
//  Constant.swift
//  My Meeting Card
//
//  Created by pranjali kashyap on 04/03/22.
//


import UIKit

class UserDetail: NSObject {
    
static let shared = UserDetail()
    private override init() { }
    
    
    func setEmailId(_ email:String) -> Void {
        UserDefaults.standard.set(email, forKey: UserKeys.email.rawValue)
    }
    func getEmailId() -> String {
        if let email = UserDefaults.standard.value(forKey: UserKeys.email.rawValue) as? String
        {
            return email
        }
        return ""
    }
    func setNamel(_ name:String) -> Void {
        UserDefaults.standard.set(name, forKey: UserKeys.name.rawValue)
    }
    func getNamel() -> String {
        if let name = UserDefaults.standard.value(forKey: UserKeys.name.rawValue) as? String
        {
            return name
        }
        return ""
    }
    
    func removeName() -> Void {
        UserDefaults.standard.removeObject(forKey: UserKeys.name.rawValue)
    }
    
    func setPreviousUserId(_ sUserId:String) -> Void {
        UserDefaults.standard.set(sUserId, forKey: UserKeys.previousUserId.rawValue)
        print(sUserId)
    }
    func getPreviousUserId() -> String {
        if let userId = UserDefaults.standard.value(forKey: UserKeys.previousUserId.rawValue) as? String
        {
            return userId
        }
        return ""
    }
    
    func setUserId(_ sUserId:String) -> Void {
        UserDefaults.standard.set(sUserId, forKey: UserKeys.userid.rawValue)
        print(sUserId)
    }
    func getUserId() -> String {
        if let userId = UserDefaults.standard.value(forKey: UserKeys.userid.rawValue) as? String
        {
            return userId
        }
        return ""
    }
    
    
    func setIndexId(_ sIndexId:String) -> Void {
        UserDefaults.standard.set(sIndexId, forKey: UserKeys.indexID.rawValue)
        print(sIndexId)
    }
    func getIndexID() -> String {
        if let indexID = UserDefaults.standard.value(forKey: UserKeys.indexID.rawValue) as? String
        {
            return indexID
        }
        return ""
    }
  
    func removeUserId() -> Void {
        UserDefaults.standard.removeObject(forKey: UserKeys.userid.rawValue)
    }
    func removeIndexID() -> Void {
        UserDefaults.standard.removeObject(forKey: UserKeys.indexID.rawValue)
    }
    //
    func setuser_breederLogin(_ suser_breederLogin:String) -> Void {
        UserDefaults.standard.set(suser_breederLogin, forKey: UserKeys.user_breederLogin.rawValue)
        print(suser_breederLogin)
    }
    func getuser_breederLogin() -> String {
        if let user_breederLogin = UserDefaults.standard.value(forKey: UserKeys.user_breederLogin.rawValue) as? String
        {
            return user_breederLogin
        }
        return ""
    }
  
    func removeuser_breederLogin() -> Void {
        UserDefaults.standard.removeObject(forKey: UserKeys.user_breederLogin.rawValue)
    }
    
    
    func setLongitude(_ sLongitude:String) -> Void {
        UserDefaults.standard.set(sLongitude, forKey: UserKeys.Longitude.rawValue)
    }
    func getLongitude() -> String {
        if let Longitude = UserDefaults.standard.value(forKey: UserKeys.Longitude.rawValue) as? String
        {
            return Longitude
        }
        return ""
    }
    func setlattitude(_ slattitude:String) -> Void {
        UserDefaults.standard.set(slattitude, forKey: UserKeys.lattitude.rawValue)
    }
    func getlattitude() -> String {
        if let lattitude = UserDefaults.standard.value(forKey: UserKeys.lattitude.rawValue) as? String
        {
            return lattitude
        }
        return ""
    }
    func setLoginBy(_ sloginby:String) -> Void {
        UserDefaults.standard.set(sloginby, forKey: UserKeys.LoginBy.rawValue)
    }
    func getLoginBy() -> String {
        if let loginby = UserDefaults.standard.value(forKey: UserKeys.LoginBy.rawValue) as? String
        {
            return loginby
        }
        return ""
    }
    func removelattitude() -> Void {
        UserDefaults.standard.removeObject(forKey: UserKeys.lattitude.rawValue)
    }
    func removelongitude() -> Void {
        UserDefaults.standard.removeObject(forKey: UserKeys.Longitude.rawValue)
    }
    
    func removeLoginBy() -> Void {
        UserDefaults.standard.removeObject(forKey: UserKeys.LoginBy.rawValue)
    }
    
    func savedSortBy(_ sort:String) -> Void {
        UserDefaults.standard.set(sort, forKey: UserKeys.savedSort.rawValue)
    }
    func getSortBy() -> String {
        if let savedSort = UserDefaults.standard.value(forKey: UserKeys.savedSort.rawValue) as? String
        {
            return savedSort
        }
        return ""
    }
}

enum UserKeys:String {
    case userid = "user_id"
    case name = "name"
    case email = "email"
    case user_breederLogin = "user_breederLogin"
    case lattitude = "lattitude"
    case Longitude = "Longitude"
    case indexID = "index"
    case LoginBy = "Loginby"
    case previousUserId = "previousUserId"
    case savedSort = "savedSort"
}
 
