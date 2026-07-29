//
//  BookmarkPopUpVC.swift
//  SpeedListners
//  Created by ravi on 19/08/22.
//

import UIKit
import MediaPlayer

protocol DelegateforBookmarkPopUpVC {
    func MethodforPop(string:String)
    
}

class BookmarkPopUpVC: UIViewController,UITextViewDelegate {
  
    @IBOutlet weak var txt_notes: UITextView!
    @IBOutlet weak var lblCount_message: UILabel!
    @IBOutlet weak var staredBookMark: UIButton!
    @IBOutlet weak var btnSave: UIButton!
    
    var book:Book!
    var capturedTime: TimeInterval? = {
        guard PlayerManager.shared.currentBook != nil else { return nil }
        return PlayerManager.shared.currentTime
    }()
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
    
    let playbackRate = PlayerManager.shared.speed
    let baseDuration: Double = 10.0

    lazy var calculatedDuration: Double = {
            return baseDuration / Double(playbackRate)
        }()
    
    lazy var displayDuration: Double = {
          max(1.5, calculatedDuration)
      }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.bookmarkCommand.isEnabled = true
        commandCenter.likeCommand.localizedTitle = "Bookmark"
        commandCenter.likeCommand.addTarget{ (_) -> MPRemoteCommandHandlerStatus in
            print("🔖 Bookmark button pressed from lock screenhytythythythythyth")
            return .success
          
        }
        setupView()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
       
        if index == nil {
       
                scheduleAutoDismiss()
         
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
    }
    
    func scheduleAutoDismiss() {
     
        let playbackRate = Double(PlayerManager.shared.speed)
        let baseDuration: Double = 10.0
        let calculatedDuration = baseDuration / playbackRate
        let displayDuration = max(1.5, calculatedDuration)

        print("[BookmarkPopUpVC] Popup will stay for \(displayDuration) seconds at rate: \(playbackRate)x")

        DispatchQueue.main.asyncAfter(deadline: .now() + displayDuration) { [weak self] in
            if self?.tapOnText == 0 {
                guard let self = self else { return }
                if self.presentingViewController != nil {
                    self.dismiss(animated: true) {
                        if self.playerstaus {
                            PlayerManager.shared.play()
                        } else {
                            PlayerManager.shared.pause()
                        }
                        self.view.removeFromSuperview()
                        self.delegateBookmarkVC?.MethodforPop(string: "")
                        self.saveWithoutNote()
                    }
                }
            }
        }
    }

    
    private func setupView(){
        
        txt_notes.delegate = self
        if self.book == nil {
            self.book = PlayerManager.shared.currentBook ?? currentBok
        }
        guard let book = self.book else { return }

        if capturedTime == nil {
            if PlayerManager.shared.currentBook?.identifier == book.identifier {
                capturedTime = PlayerManager.shared.currentTime
            } else {
                capturedTime = book.currentTime
            }
        }

        let savedBookmarks = BookmarkManager.shared.loadBookmarks(for: self.book)
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
                    let isStar =  BookmarkCacheManager.getIsStar(for: segment.identifiers) ?? false
                    self.starStatus = isStar
                    if self.starStatus == false{
                        
                        staredBookMark.setBackgroundImage(UIImage(named: "blank_star"), for: .normal)
                    }else{
                        staredBookMark.setBackgroundImage(UIImage(named: "filled_star"), for: .normal)
                    }
                    
                }
               
            }
            
        }
        guard let index = self.index else {return}
        self.i = String(index)
        guard let txt = self.txt else {return}
        self.txt_notes.text = txt
       
    }
    
//    @objc func timerTap(){
//        print("timer")
//        guard self.book != nil else {
//            DispatchQueue.main.async{
//                self.showToast("Please add a book to the library if already added then play")
//                self.dismiss(animated: true)
//            }
//            return
//        }
//        runCount += 1
//        if runCount == 3 && tapOnText == 0  {
//            self.timer.invalidate()
//            self.dismiss(animated: true) {
//                
//                if self.playerstaus == true{
//                    PlayerManager.shared.play()
//                }else{
//                    PlayerManager.shared.pause()
//                }
//                self.view.removeFromSuperview()
//                self.delegateBookmarkVC?.MethodforPop(string: "")
//                self.saveWithoutNote()
//            }
//        }
//    }
    
  
    
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
    
    func textViewDidEndEditing(_ textView: UITextView) {}
    
    @IBAction func btnDone_Action(_ sender: UIButton) {
        guard self.book != nil else {
            DispatchQueue.main.async{
                self.showToast("Please add a book to the library if already added then play")
                self.dismiss(animated: true)
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

                BookmarkManager.shared.updateBookmark(
                    book: self.book,
                    index: index,
                    note: self.txt_notes.text ?? "",
                    starStatus: starStatus
                ) { [weak self] success in
                    guard let self = self, success else { return }
                    DispatchQueue.main.async {
                        self.dismiss(animated: true) {
                            self.delegateBookmarkVC?.MethodforPop(string: self.txt_notes.text ?? "")
                            self.showToast("saved succefully")
                            if self.playerstaus == true {
                                PlayerManager.shared.play()
                            } else {
                                PlayerManager.shared.pause()
                            }
                            self.view.removeFromSuperview()
                        }
                    }
                }

            case .segment(let segment):
                let identifier = segment.identifiers.replacingOccurrences(of: " ", with: "")
                BookmarkCacheManager.saveNotes(self.txt_notes.text, for: identifier)
                BookmarkCacheManager.saveIsStar(starStatus, for: identifier)
                print(segment,identifier,"identifier")
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
            let note = self.txt_notes.text ?? ""
            let completion: (Bool) -> Void = { [weak self] success in
                guard let self = self, success else { return }
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        self.delegateBookmarkVC?.MethodforPop(string: self.txt_notes.text ?? "")
                        self.showToast("saved succefully")
                        if self.playerstaus == true {
                            PlayerManager.shared.play()
                        } else {
                            PlayerManager.shared.pause()
                        }
                        self.view.removeFromSuperview()
                    }
                }
            }

            if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                BookmarkManager.shared.saveWithoutNote(
                    book: self.book,
                    starStatus: self.starStatus,
                    timestamp: capturedTime,
                    completion: completion
                )
            } else {
                BookmarkManager.shared.saveBookmarkWithNote(
                    book: self.book,
                    note: note,
                    starStatus: self.starStatus,
                    timestamp: capturedTime,
                    completion: completion
                )
            }
        }
            
    }
    
    @objc func saveWithoutNote(){
        guard self.book != nil else {
            DispatchQueue.main.async{
                self.showToast("Please add a book to the library if already added then play")
                self.dismiss(animated: true)
            }
            return
        }
        if displayItems.count <= 0 {
            BookmarkManager.shared.saveWithoutNote(
                book: self.book,
                starStatus: self.starStatus,
                timestamp: capturedTime
            ) { [weak self] success in
                guard let self = self, success else { return }
                DispatchQueue.main.async {
                    self.dismiss(animated: true) {
                        AudioMonitorManager.shared.startTranscribeAllBookmarksInBackground(book: self.book)
                        self.delegateBookmarkVC?.MethodforPop(string: self.txt_notes.text ?? "")
                        if self.playerstaus == true{
                            PlayerManager.shared.play()
                        }else{
                            PlayerManager.shared.pause()
                        }
                        self.view.removeFromSuperview()
                    }
                }
            }
        }
        
        
    }
    
    @IBAction func btnCross_Actioin(_ sender: UIButton) {
        
        self.dismiss(animated: true) {
            self.view.removeFromSuperview()
            self.delegateBookmarkVC?.MethodforPop(string: "")
            
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
                AudioMonitorManager.shared.startTranscribeAllBookmarksInBackground(book: self.book)
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
        dateFormatter.dateFormat = "MM/dd/yyyy hh:mm a" 
        return dateFormatter.string(from: Date())
    }
}
