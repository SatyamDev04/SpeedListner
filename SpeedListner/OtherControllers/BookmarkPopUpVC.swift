//
//  BookmarkPopUpVC.swift
//  SpeedListners
//  Created by ravi on 19/08/22.
//

import UIKit

protocol DelegateforBookmarkPopUpVC {
    func MethodforPop(string:String)
    
}

class BookmarkPopUpVC: UIViewController,UITextViewDelegate {
    let COMMENTS_LIMIT = 255
    @IBOutlet weak var txt_notes: UITextView!
    @IBOutlet weak var lblCount_message: UILabel!
    
    var delegateBookmarkVC:DelegateforBookmarkPopUpVC? = nil
    var arrBookmarksNotes = [BookmarksModel]()
    var book:Book!
    var txt:String?
    var index:Int?
    var i = ""
    var runCount = 0
    var tapOnText = 0
    var timer = Timer()
    var starStatus = false
   var playerstaus = false
    @IBOutlet weak var staredBookMark: UIButton!
    @IBOutlet weak var btnSave: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
       txt_notes.delegate = self
       // txt_notes.text = "Add Additional Notes Here…"
      //  btnSave.backgroundColor = UIColor.gray
        //txt_notes.textColor = UIColor.gray
        
//        if btnSave.backgroundColor == UIColor.gray {
//            btnSave.isUserInteractionEnabled = false
//        }
//        else {
//            btnSave.isUserInteractionEnabled = true
//        }
        guard let book = currentBok else {return}
        self.book = book
        
        
        let userDefaults = UserDefaults.standard
        // 1
        if let savedData = userDefaults.object(forKey: (self.book.identifier ?? "")+"_bookmarks") as? Data {
            
            do{
                // 2
                let savedBookmarks = try JSONDecoder().decode([BookmarksModel].self, from: savedData)
                if savedBookmarks.count > 0 {
                    self.arrBookmarksNotes = savedBookmarks
                    if let index = self.index{
                        self.starStatus = self.arrBookmarksNotes[index].isStar ?? false
                        if self.starStatus == false{
                            
                            staredBookMark.setBackgroundImage(UIImage(named: "blank_star"), for: .normal)
                        }else{
                           
                            staredBookMark.setBackgroundImage(UIImage(named: "filled_star"), for: .normal)
                        }
                    }
                    
                }
            } catch {
                // Failed to convert Data to Contact
            }
        }
        guard let txt = self.txt,let index = self.index else {return}
        self.txt_notes.text = txt
        self.i = String(index)
        
       
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
        if let index = index {
            
        }else{
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerTap), userInfo: nil, repeats: true)
        }
    }
    
    @objc func timerTap(){
        print("timer")
        runCount += 1
        if runCount == 3 && tapOnText == 0  {
            self.timer.invalidate()
            self.dismiss(animated: true) {
                
                if self.playerstaus == true{
                    PlayerManager.shared.play()
                }else{
                    PlayerManager.shared.pause()
                }
                self.view.removeFromSuperview()
                self.delegateBookmarkVC?.MethodforPop(string: "")
                self.saveWithoutNote()
            }
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    @IBAction func starBtnTap(_ sender: UIButton) {
        if self.starStatus == false{
            staredBookMark.setBackgroundImage(UIImage(named: "filled_star"), for: .normal)
            starStatus = true
        }else{
            staredBookMark.setBackgroundImage(UIImage(named: "blank_star"), for: .normal)
            starStatus = false
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        let words = txt_notes.text.components(separatedBy: .whitespacesAndNewlines)
        let filteredWords = words.filter({ (word) -> Bool in
            word != ""
        })
        let wordCount = filteredWords.count
        
        lblCount_message.text = String(wordCount)
        //lblCount_message.text = String(txt_notes.text.count)
        //  print("chars \(txt_notes.text.count) \( text)")
        
        if(wordCount > 99 && range.length == 0) {
            showAlert(for: "Please summarize in 100 words or less")
            print("Please summarize in 100 words or less")
            return false
        }
        return true
    }
    func textViewDidBeginEditing(_ textView: UITextView) {
        if PlayerManager.shared.isPlaying{
          PlayerManager.shared.pause()
         }
//        if txt_notes.textColor == UIColor.gray {
////            if txt_notes.text == "Add Additional Notes Here…"{
////                txt_notes.text = ""
//                self.timer.invalidate()
//            }
//            
//            
////            txt_notes.textColor = UIColor.black
////            btnSave.backgroundColor =  #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1)
////            if btnSave.backgroundColor == UIColor.gray {
//          //      btnSave.isUserInteractionEnabled = false
//            }
//            else {
//           //     btnSave.isUserInteractionEnabled = true
//            }
//        }
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        
//        if txt_notes.text == "" {
//            txt_notes.textColor = UIColor.gray
//          //  txt_notes.text = "Add Additional Notes Here…"
//            txt_notes.textColor = UIColor.gray
//           // btnSave.backgroundColor = UIColor.gray
//            if btnSave.backgroundColor == UIColor.gray {
//                //btnSave.isUserInteractionEnabled = false
//            }
//            else {
//              //  btnSave.isUserInteractionEnabled = true
//            }
//            
//        }
    }
    
    @IBAction func btnDone_Action(_ sender: UIButton) {
        
        if self.i != "" {
            
            guard let  ind = Int(self.i) else {return}
            
            let t = self.arrBookmarksNotes[ind].timeStamp
            let time = self.arrBookmarksNotes[ind].time
            let date = self.arrBookmarksNotes[ind].date
            
            self.arrBookmarksNotes[ind] = BookmarksModel(indentifier: self.book.identifier ?? "" , bookmarksTxt: self.txt_notes.text ?? "", timeStamp: t, time: time, date: date, isStar: starStatus)
            self.saveBookMarksNotes()
        }else{
            
            let t = self.book.currentTime
            let time = formatTime(Int(self.book.currentTime))
            let date = Date.getCurrentDate()
            self.arrBookmarksNotes.append(BookmarksModel(indentifier: self.book.identifier ?? "", bookmarksTxt: self.txt_notes.text ?? "", timeStamp: t, time: time, date: date, isStar: starStatus))
            self.saveBookMarksNotes()
        }
        
        
        
    }
    func saveWithoutNote(){
        
        if self.i != "" {
            
            guard let  ind = Int(self.i) else {return}
            
            let t = self.arrBookmarksNotes[ind].timeStamp
            let time = self.arrBookmarksNotes[ind].time
            let date = self.arrBookmarksNotes[ind].date
            
            self.arrBookmarksNotes[ind] = BookmarksModel(indentifier: self.book.identifier ?? "", bookmarksTxt:  "", timeStamp: t, time: time, date: date, isStar: starStatus)
            self.saveBookMarksNotes()
            
        }else{
            
            let t = self.book.currentTime
            let time = formatTime(Int(self.book.currentTime))
            let date = Date.getCurrentDate()
            self.arrBookmarksNotes.append(BookmarksModel(indentifier: self.book.identifier ?? "", bookmarksTxt: "", timeStamp: t, time: time, date: date, isStar: starStatus))
            self.saveBookMarksNotes()
        }
        
        
        
    }
    
    @IBAction func btnCross_Actioin(_ sender: UIButton) {
        self.dismiss(animated: true) {
            self.view.removeFromSuperview()
            self.delegateBookmarkVC?.MethodforPop(string: "")
            if self.txt_notes.text == ""{
                self.saveWithoutNote()
            }
        }
        
    }
    
    
}


extension BookmarkPopUpVC {
    func saveBookMarksNotes(){
        do {
            // 1
            let encodedData = try JSONEncoder().encode(self.arrBookmarksNotes)

            
            let userDefaults = UserDefaults.standard
            // 2
            userDefaults.set(encodedData, forKey: (self.book.identifier ?? "")+"_bookmarks")
            
            self.dismiss(animated: true) {
      
                self.delegateBookmarkVC?.MethodforPop(string: self.txt_notes.text ?? "")
                self.showToast("saved succefully")
                if self.playerstaus == true{
                    PlayerManager.shared.play()
                }else{
                    PlayerManager.shared.pause()
                }
                self.view.removeFromSuperview()
            }

        } catch {
            // Failed to encode Contact to Data
            self.dismiss(animated: true) {
                if self.playerstaus == true{
                    PlayerManager.shared.play()
                }else{
                    PlayerManager.shared.pause()
                }
                self.delegateBookmarkVC?.MethodforPop(string: self.txt_notes.text ?? "")
                print("something went wrong while saving bookmarks")
                self.showToast("something went wrong while saving bookmarks")
                self.view.removeFromSuperview()
            }
        }

    }
}
extension Date {

 static func getCurrentDate() -> String {

        let dateFormatter = DateFormatter()

        dateFormatter.dateFormat = "MM/dd/yyyy"

        return dateFormatter.string(from: Date())

    }
}
