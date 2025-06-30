//
//  ModelClass.swift
//  SpeedListners
//
//  Created by ravi on 20/12/22.
//
import Foundation
import UIKit


class ModelClass: NSObject {
    
    static let shared = ModelClass()
    private override init() { }
    
    //MARK:- Get information All FAQ Data:-
    
    var id : String?
    var faq_question : String?
    var faq_answer : String?
    var active : String?
    var created_at : String?
    var updated_at : String?
    
    class func getAllFAQ(responseArray : [[String : Any]])-> [ModelClass] {
        
        var getAllFAQArr = [ModelClass]()
        for tempDict in responseArray{
            let tempobj = ModelClass()
            
            tempobj.id = tempDict.validatedValue("id", expected: "" as AnyObject) as! String
            tempobj.faq_question = tempDict.validatedValue("faq_question", expected: "" as AnyObject) as! String
            tempobj.faq_answer = tempDict.validatedValue("faq_answer", expected: "" as AnyObject) as! String
            tempobj.active = tempDict.validatedValue("active", expected: "" as AnyObject) as! String
            tempobj.created_at = tempDict.validatedValue("created_at", expected: "" as AnyObject) as! String
            tempobj.updated_at = tempDict.validatedValue("updated_at", expected: "" as AnyObject) as! String
            
            getAllFAQArr.append(tempobj)
            
        }
        
        return getAllFAQArr
    }
    
    // Get About us
  //  var id : String?
    var about_name : String?
  
    
    class func getAllAboutUs(responseArray : [[String : Any]])-> [ModelClass] {
        
        var getAboutUsArr = [ModelClass]()
        for tempDict in responseArray{
            let tempobj = ModelClass()
            
            tempobj.id = tempDict.validatedValue("id", expected: "" as AnyObject) as! String
            tempobj.about_name = tempDict.validatedValue("about_name", expected: "" as AnyObject) as! String
            
            getAboutUsArr.append(tempobj)
            
        }
        
        return getAboutUsArr
    }
    
    
    // Get TermCondition
  //  var id : String?
    var term_name : String?
  
    
    class func getTermCondition(responseArray : [[String : Any]])-> [ModelClass] {
        
        var getTermConditionArr = [ModelClass]()
        for tempDict in responseArray{
            let tempobj = ModelClass()
            
            tempobj.id = tempDict.validatedValue("id", expected: "" as AnyObject) as! String
            tempobj.term_name = tempDict.validatedValue("term_name", expected: "" as AnyObject) as! String
            
            getTermConditionArr.append(tempobj)
            
        }
        
        return getTermConditionArr
    }
    
    // Get PrivacyPolicy
  //  var id : String?
    var privacy_name : String?
  
    
    class func getPrivacyPolicy(responseArray : [[String : Any]])-> [ModelClass] {
        
        var getPrivacyPolicyArr = [ModelClass]()
        for tempDict in responseArray{
            let tempobj = ModelClass()
            
            tempobj.id = tempDict.validatedValue("id", expected: "" as AnyObject) as! String
            tempobj.privacy_name = tempDict.validatedValue("privacy_name", expected: "" as AnyObject) as! String
            
            getPrivacyPolicyArr.append(tempobj)
            
        }
        
        return getPrivacyPolicyArr
    }
    
    //getProfile
   
    var name : String?
    var email : String?
    var phone : String?
    var image : String?
   
    
    class func getProfile(responseArray : [[String : Any]])-> [ModelClass] {
        
        var getProfileArr = [ModelClass]()
        for tempDict in responseArray{
            let tempobj = ModelClass()
            
            tempobj.name = tempDict.validatedValue("name", expected: "" as AnyObject) as! String
            tempobj.email = tempDict.validatedValue("email", expected: "" as AnyObject) as! String
            tempobj.phone = tempDict.validatedValue("phone", expected: "" as AnyObject) as! String
            tempobj.image = tempDict.validatedValue("image", expected: "" as AnyObject) as! String
            getProfileArr.append(tempobj)
            
        }
        
        return getProfileArr
    }
    
    //GetFolderData
    
    var chapter_id : String?
    var folder_name : String?
    var total_duration : String?
    
    
    class func GetFolderData(responseArray : [[String : Any]])-> [ModelClass] {
        
        var GetFolderDataArr = [ModelClass]()
        for tempDict in responseArray{
            let tempobj = ModelClass()
            
            tempobj.folder_name = tempDict.validatedValue("folder_name", expected: "" as AnyObject) as! String
            tempobj.total_duration = tempDict.validatedValue("total_duration", expected: "" as AnyObject) as! String
            
            tempobj.chapter_id = tempDict.validatedValue("chapter_id", expected: "" as AnyObject) as! String
            
            GetFolderDataArr.append(tempobj)
            
        }
        
        return GetFolderDataArr
    }
    
    //GetBookInFolder
    
    var chapter_file : String?
   
    
    class func GetBookInFolder(responseArray : [[String : Any]])-> [ModelClass] {
        
        var GetBookInFolderArr = [ModelClass]()
        for tempDict in responseArray{
            let tempobj = ModelClass()
            
            tempobj.chapter_file = tempDict.validatedValue("chapter_file", expected: "" as AnyObject) as! String
          
         
          
            
            GetBookInFolderArr.append(tempobj)
            
        }
        
        return GetBookInFolderArr
    }
    

}
struct ChapepterListModel: Codable {
    let msg, msgType, status: String
    let code: Int
    let data: [ChapterSongData]
    let chapterFileSpeed: Int
    let chapterFileTime: String
    let chapterPauseTime: Int
    let bookmark: String
    let lSong:String

    enum CodingKeys: String, CodingKey {
        case msg
        case msgType = "msg_type"
        case status, code, data
        case chapterFileSpeed = "chapter_file_speed"
        case chapterFileTime = "chapter_file_time"
        case chapterPauseTime = "chapter_pause_time"
        case bookmark
        case lSong = "l_song"
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.msg = try container.decodeIfPresent(String.self, forKey: .msg) ?? ""
        self.msgType = try container.decodeIfPresent(String.self, forKey: .msgType) ?? ""
        self.status = try container.decodeIfPresent(String.self, forKey: .status) ?? ""
        self.code = try container.decodeIfPresent(Int.self, forKey: .code) ?? 0
        self.data = try container.decodeIfPresent([ChapterSongData].self, forKey: .data) ?? []
        self.chapterFileSpeed = try container.decodeIfPresent(Int.self, forKey: .chapterFileSpeed) ?? 0
        self.chapterFileTime = try container.decodeIfPresent(String.self, forKey: .chapterFileTime) ?? ""
        self.chapterPauseTime = try container.decodeIfPresent(Int.self, forKey: .chapterPauseTime) ?? 0
        self.bookmark = try container.decodeIfPresent(String.self, forKey: .bookmark) ?? ""
        self.lSong = try container.decodeIfPresent(String.self, forKey: .lSong) ?? ""
    }
}

// MARK: - Datum
struct ChapterSongData: Codable {
    let chapterFile: String

    enum CodingKeys: String, CodingKey {
        case chapterFile = "chapter_file"
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.chapterFile = try container.decodeIfPresent(String.self, forKey: .chapterFile) ?? ""
    }
}
