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
  
    @IBOutlet weak var txt_notes: UITextView!
    @IBOutlet weak var lblCount_message: UILabel!
    @IBOutlet weak var staredBookMark: UIButton!
    @IBOutlet weak var btnSave: UIButton!
    
    var book:Book!
    var txt:String?
    var index:Int?
    var i = ""
    var runCount = 0
    var tapOnText = 0
    var timer = Timer()
    var starStatus = false
    var playerstaus = false
    var delegateBookmarkVC:DelegateforBookmarkPopUpVC? = nil
    var arrBookmarksNotes = [BookmarksModel]()
    var displayItems: [BookmarkDisplayItem] = []
    let COMMENTS_LIMIT = 255
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard (book != nil) else {
            self.showToast("Please add a book to the library. If already added, then press Play.")
            return
        }
        
        if index == nil {
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(timerTap), userInfo: nil, repeats: true)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    private func setupView(){
        
        txt_notes.delegate = self
        guard let book = currentBok else {return}
        self.book = book
        
        
        let userDefaults = UserDefaults.standard
        if let savedData = userDefaults.object(forKey: (self.book.identifier ?? "")+"_bookmarks") as? Data {
            
            do{
                let savedBookmarks = try JSONDecoder().decode([BookmarksModel].self, from: savedData)
                if savedBookmarks.count > 0 {
                    self.arrBookmarksNotes = savedBookmarks
                    if let index = self.index{
                        let item = displayItems[index]
                        switch item {
                        case .bookmark(let bookmark):
                            
                            self.starStatus = bookmark.isStar ?? false
                            if self.starStatus == false{
                                
                                staredBookMark.setBackgroundImage(UIImage(named: "blank_star"), for: .normal)
                            }else{
                               
                                staredBookMark.setBackgroundImage(UIImage(named: "filled_star"), for: .normal)
                            }
                            
                        case .segment(let segment):
                            
                            self.starStatus = segment.isStar ?? false
                            if self.starStatus == false{
                                
                                staredBookMark.setBackgroundImage(UIImage(named: "blank_star"), for: .normal)
                            }else{
                                staredBookMark.setBackgroundImage(UIImage(named: "filled_star"), for: .normal)
                            }
                            
                        }
                        
                      
                    }
                    
                }
            } catch {
            }
        }
        guard let index = self.index else {return}
        self.i = String(index)
        guard let txt = self.txt else {return}
        self.txt_notes.text = txt
       
        
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
        tapOnText = 1
    }
    func textViewDidEndEditing(_ textView: UITextView) {
        

    }
    
    @IBAction func btnDone_Action(_ sender: UIButton) {
        guard (self.book != nil) else {
            self.showToast("Please add a book to the library. If already added, then press Play.")
            self.dismiss(animated: true) {
                self.view.removeFromSuperview()
            }
            return
            
        }
        self.timer.invalidate()
        if self.i != "" {
            
            guard let  ind = Int(self.i) else {return}
            let item = displayItems[ind]
            switch item {
            case .bookmark(let bookmark):
                guard let index = self.arrBookmarksNotes.firstIndex(where: { arrBookmark in
                    arrBookmark.timeStamp == bookmark.timeStamp
                    
                }) else {return}
                
                let t = self.arrBookmarksNotes[index].timeStamp
                let time = self.arrBookmarksNotes[index].time
                let date = self.arrBookmarksNotes[index].date
                
                self.arrBookmarksNotes[index] = BookmarksModel(indentifier: self.book.identifier ?? "" , bookmarksTxt: self.txt_notes.text ?? "", timeStamp: t, time: time, date: date, isStar: starStatus)
                
                self.saveBookMarksNotes()
                
            case .segment(let segment):
                let identifier = segment.identifiers
                BookmarkCacheManager.saveNotes(self.txt_notes.text, for: identifier)
                BookmarkCacheManager.saveIsStar(starStatus, for: identifier)
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
            }
            
            
            
        }else{
            
            let t = self.book.currentTime
            let time = formatTime(Int(self.book.currentTime))
            let date = Date.getCurrentDate()
            self.arrBookmarksNotes.append(BookmarksModel(indentifier: self.book.identifier ?? "", bookmarksTxt: self.txt_notes.text ?? "", timeStamp: t, time: time, date: date, isStar: starStatus))
            self.saveBookMarksNotes()
        }
        
        
        
    }
    func saveWithoutNote(){
        
        if displayItems.count <= 0 {
            let t = self.book.currentTime
            let time = formatTime(Int(self.book.currentTime))
            let date = Date.getCurrentDate()
            self.arrBookmarksNotes.append(BookmarksModel(indentifier: self.book.identifier ?? "", bookmarksTxt: "", timeStamp: t, time: time, date: date, isStar: starStatus))
            self.saveBookMarksNotes()
            
        }
        
        
    }
    
    @IBAction func btnCross_Actioin(_ sender: UIButton) {
        self.timer.invalidate()
        self.dismiss(animated: true) {
            self.view.removeFromSuperview()
            self.delegateBookmarkVC?.MethodforPop(string: "")
            if self.txt_notes.text == ""{
                guard (self.book != nil) else {
                    self.showToast("Please add a book to the library. If already added, then press Play.")
                    return
                }
                self.saveWithoutNote()
            }
        }
        
    }
    
    
}


extension BookmarkPopUpVC {
    func saveBookMarksNotes(){
        do {
           
            let encodedData = try JSONEncoder().encode(self.arrBookmarksNotes)
            let userDefaults = UserDefaults.standard
           
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
