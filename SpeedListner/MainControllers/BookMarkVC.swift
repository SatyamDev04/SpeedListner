//
//  BookMarkVC.swift
//  SpeedListners
//
//  Created by ravi on 19/08/22.
//

import UIKit
import DropDown
import MessageUI

enum SortType {
    case byTime
    case byDate
}


class BookMarkVC: UIViewController,UITableViewDelegate, UITableViewDataSource,BookMarkCellDelegate, DelegateforBookmarkPopUpVC {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var btnSort: UIButton!
    @IBOutlet weak var tblV: UITableView!
    @IBOutlet weak var currentTitleBook: UILabel!
    @IBOutlet weak var effectView: UIVisualEffectView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerImageView: UIImageView!
    @IBOutlet weak var footerTitleLabel: UILabel!
    @IBOutlet weak var footerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var footerPlayButton: UIButton!
    @IBOutlet weak var bookmarksCountLable: UILabel!
    @IBOutlet weak var transCribeBtn: UIButton!
    @IBOutlet weak var autoTranscribeChecked: UIButton!
    
    // MARK: - Properties
    
    let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
    let topMenu = DropDown()
    let DownMenu = DropDown()
    lazy var dropDowns: [DropDown] = { [topMenu, DownMenu] }()

    var arrBookmarksNotes = [BookmarksModel]()
    var arrMergedBookmarksNotes = [BookmarkSegment]()
    var displayItems: [BookmarkDisplayItem] = []
    var book: Book!
    var dataBack: (_ t: Double) -> () = { _ in }

    let miniPlayImage = UIImage(named: "29")
    let miniPauseButton = UIImage(named: "21")
    var currentSortType: SortType = .byTime
    var currentPlayingStatus: Bool = false
    let aiLoader = AILoaderView()

    var isAutoTranscribeEnabled: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "autoTranscribeWhileListening")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "autoTranscribeWhileListening")
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        getBookmarks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if PlayerManager.shared.isPlaying {
            footerView.isHidden = false
        }
        guard let b = currentBok else { return }
        setupMiniPlayer(book: b)
        if isAutoTranscribeEnabled{
            self.autoTranscribeChecked.setImage(UIImage(named: "ic_outline-check-box"), for: .normal)
        }
    }

    // MARK: - Setup
    
    func setupUI() {
        tblV.addCorner5()
        tblV.addShadow5()
        handleObservers()
        tblV.register(UINib(nibName: "BookMarkCell", bundle: nil), forCellReuseIdentifier: "BookMarkCell")
        tblV.register(UINib(nibName: "BookMarkExpandCell", bundle: nil), forCellReuseIdentifier: "BookMarkExpandCell")
        tblV.register(UINib(nibName: "MergeBookMarkCell", bundle: nil), forCellReuseIdentifier: "MergeBookMarkCell")
        tblV.delegate = self
        tblV.dataSource = self
        transCribeBtn.addTarget(self, action: #selector(transcribeAllBtnAction), for: .touchUpInside)
        
        autoTranscribeChecked.addTarget(self, action: #selector(autoTranscribeCheckAction), for: .touchUpInside)
    }

    func handleObservers() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didPressShowDetail(_:)))
        effectView.addGestureRecognizer(tapRecognizer)
        effectView.isUserInteractionEnabled = true

        footerView.clipsToBounds = true
        footerView.layer.cornerRadius = 20
        footerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]

        NotificationCenter.default.addObserver(self, selector: #selector(onBookPlay), name: Notification.Name.AudiobookPlayer.bookPlayed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onBookPause), name: Notification.Name.AudiobookPlayer.bookPaused, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onBookPause), name: Notification.Name.AudiobookPlayer.bookEnd, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onBookStop(_:)), name: Notification.Name.AudiobookPlayer.bookStopped, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bookChange(_:)), name: Notification.Name.AudiobookPlayer.bookChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(bookReady(_:)), name: Notification.Name.AudiobookPlayer.bookReady, object: nil)
    }
    
    func getBookmarks(){
        
        guard let book = currentBok else {return}
        self.book = book
        self.currentTitleBook.text = book.title
        
        let userDefaults = UserDefaults.standard
        if let savedData = userDefaults.object(forKey: (self.book.identifier ?? "")+"_bookmarks") as? Data {
            
            do{
                let savedBookmarks = try JSONDecoder().decode([BookmarksModel].self, from: savedData)
                if savedBookmarks.count > 0 {
                    self.arrBookmarksNotes = savedBookmarks
                    updateBookmarkSummary()
                    mergeAdjecntBookmarks()
                }
            } catch {
                
            }
        }
        
        UserDefaults.standard.set("ByTime", forKey: "BookmarkSorting")
        if let sort = UserDefaults.standard.object(forKey: "BookmarkSorting") as? String,sort == "ByDate"{
            self.currentSortType = .byDate
            self.sortBookmarks()
        }else{
            self.currentSortType = .byTime
            self.sortBookmarks()
        }
    }
    
    
    private func updateBookmarkSummary() {
        let totalBookmarks = arrBookmarksNotes.count
        let starCount = arrBookmarksNotes.filter { $0.isStar == true }.count
        let notesCount = arrBookmarksNotes.filter { !$0.bookmarksTxt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count

        let summaryText = "\(totalBookmarks) Bookmark(s)  -  \(starCount) Star(s)  -  \(notesCount) Note(s)"
        bookmarksCountLable.text = summaryText
    }
    func mergeAdjecntBookmarks() {
        let inputAudioURL: URL = book.fileURL
       
        aiLoader.show(in: view, msg: "✨ AI is enhancing your bookmarks...")
        
        AudioBookmarkExtractor.extractGroupedBookmarks(
            from: inputAudioURL,
            bookmarks: arrBookmarksNotes,
            progressHandler: { progress in
                print("Progress: \(progress * 100)%")
            },
            completion: { [weak self] success, outputURLs, error in
                DispatchQueue.main.async {
                    self?.aiLoader.dismiss()
                    if success, let urls = outputURLs {
                        urls.forEach { print("Exported file at: \($0.url)") }
                        // Play or share each URL as needed
                        self?.arrMergedBookmarksNotes = urls
                        self?.prepareDisplayItems()
                        self?.tblV.reloadData()
                        
                    } else {
                        print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        )
    }
    
    private func prepareDisplayItems() {
        displayItems = []

        for bookmark in arrBookmarksNotes {
            displayItems.append(.bookmark(bookmark))
        }

        for segment in arrMergedBookmarksNotes {
            displayItems.append(.segment(segment))
        }

        // Optional: sort display items by start time if needed
        displayItems.sort { lhs, rhs in
            let lhsTime = (lhs.startTime ?? 0)
            let rhsTime = (rhs.startTime ?? 0)
            return lhsTime < rhsTime
        }
    }
    
    @IBAction func didPressPlay(_ sender: UIButton){
        PlayerManager.shared.playPause()
        self.setPlayImage()
    }
    
    @IBAction func miniplayerCrossBtn_Action(_ sender: UIButton){
        PlayerManager.shared.miniPlayerIsHidden = true
        //  self.footerView.isHidden = true
    }
    
    @IBAction func miniplayerBookmarksBtn_Action(_ sender: UIButton){
        
        let vc: BookmarkPopUpVC = self.storyboard?.instantiateViewController(withIdentifier: "BookmarkPopUpVC") as! BookmarkPopUpVC
        vc.playerstaus = PlayerManager.shared.isPlaying
        self.addChild(vc)
        vc.view.frame = self.view.frame
        self.view.addSubview(vc.view)
        self.view.bringSubviewToFront(vc.view)
        vc.didMove(toParent: self)
        
    }
    
    @IBAction func didPressShowBtn(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: false)
    }
    
    @IBAction func didPressShowDetail(_ sender: UIButton) {
        if d {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let playerVC = storyboard.instantiateViewController(withIdentifier: "PlayerViewController2") as! PlayerViewController
            guard let b = currentBok else {return}
            playerVC.book = b
            
            tabBarController?.selectedIndex = 1
        }else{
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let playerVC = storyboard.instantiateViewController(withIdentifier: "PlayerViewController") as! PlayerViewController
            guard let b = currentBok else {return}
            playerVC.book = b
            
            tabBarController?.selectedIndex = 1
        }
        
        
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = displayItems[indexPath.row]
        switch item {
           case .bookmark(let model):
               guard let cell = tableView.dequeueReusableCell(withIdentifier: "BookMarkExpandCell", for: indexPath) as? BookMarkExpandCell else {
                   return UITableViewCell()
               }
            cell.delegate = self
            cell.selectionStyle = .none
            cell.bottomView.isHidden = true
            cell.optionBtn.tag = indexPath.row
            cell.detailtxt.text = model.bookmarksTxt
            cell.bookmarkTimelbl.text = model.time + " - " + model.date
            cell.bookmarkBtn.tag = indexPath.row
            cell.bookmarkBtn.addTarget(self, action: #selector(bookmarkTapButton(_:)), for: .touchUpInside)
            
                   if (model.bookmarksTxt.count ) > 0 || model.isStar == true{
                       cell.bottomView.isHidden = false
                   }
                   if  model.isStar ?? false {
                       cell.isStarBookMark.isHidden = false
                       cell.starBG.isHidden = false
                   }else{
                       cell.isStarBookMark.isHidden = true
                       cell.starBG.isHidden = true
                   }
                   
                   return cell
               

           case .segment(let segment):
               guard let cell = tableView.dequeueReusableCell(withIdentifier: "MergeBookMarkCell", for: indexPath) as? MergeBookMarkCell else {
                   return UITableViewCell()
               }
            
            cell.selectionStyle = .none
            cell.delegate = self
            cell.optionBtn.tag = indexPath.row
            cell.bookmarkTimelbl.text = "\(formatTime(from: segment.startTime))" + " - " + "\(formatTime(from: segment.endTime))"
            cell.playBtn.tag = indexPath.row
            cell.playBtn.addTarget(self, action: #selector(playBookmarkClip(_:)), for: .touchUpInside)
            cell.transcriptionBtn.tag = indexPath.row
            cell.transcriptionBtn.addTarget(self, action: #selector(openCombinedTranscriptionSummary(_:)), for: .touchUpInside)
            if (segment.bookmarksTxt?.count ?? 0 ) > 0 || segment.isStar == true{
                cell.bottomView.isHidden = false
            }
            if  segment.isStar ?? false {
                cell.isStarBookMark.isHidden = false
                cell.starBG.isHidden = false
            }else{
                cell.isStarBookMark.isHidden = true
                cell.starBG.isHidden = true
            }
            cell.transSumryLable.layer.cornerRadius = 12
            cell.transSumryLable.clipsToBounds = true
            
            if let cachedTranscription = BookmarkCacheManager.getTranscription(for: segment.identifiers),
               let cachedSummary = BookmarkCacheManager.getSummary(for: segment.identifiers) {
                cell.transSumryLable.text = "Transcribed & Summarized"
                cell.transSumryLable.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1)
            }else{
                let underlineAttrString = NSAttributedString(
                    string: "Transcribe & Summarize?",
                    attributes: [
                        .underlineStyle: NSUnderlineStyle.single.rawValue,
                        .foregroundColor: UIColor.white,
                        .font: UIFont.systemFont(ofSize: 14, weight: .medium)
                    ]
                )
                cell.transSumryLable.attributedText = underlineAttrString
                cell.transSumryLable.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.6)
            }
            return cell
              
           }

      
        
      
    }

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableView.automaticDimension
    }
    func formatTime(from seconds: Double) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, secs)
        } else {
            return String(format: "%02d:%02d", minutes, secs)
        }
    }

    @objc func bookmarkTapButton(_ sender:UIButton) {
        let index = sender.tag
            guard index < displayItems.count else {
                print("Index out of bounds!")
                return
            }
        let item = displayItems[index]

        switch item {
            
        case .bookmark(let model):
            let t = model.timeStamp
            self.dataBack(t)
            self.navigationController?.popViewController(animated: true)

        case .segment(let segment):
               print("Segment: \(segment.startTime)-\(segment.endTime)")
        }
        
       
    }
    
    
    @IBAction private func tapMiniPlayerButton() {
        
    }
    
    @objc func play_pauseImgSet(_ notification:Notification){
        
    }
   
    
    
    @objc func handleAudioInterruptions(_ notification:Notification){
        
        
    }
    
    
    @objc func transcribeAllBtnAction(){
        
        self.transcribeAllSegments()
    }
    
    @objc func autoTranscribeCheckAction(){
        if isAutoTranscribeEnabled {
            self.autoTranscribeChecked.setImage(UIImage(named: "ic_outline-check-box-1"), for: .normal)
            isAutoTranscribeEnabled = false
            
        }else{
            self.autoTranscribeChecked.setImage(UIImage(named: "ic_outline-check-box"), for: .normal)
            isAutoTranscribeEnabled = true
        }
        
    }
    
    @objc func playBookmarkClip(_ sender:UIButton){
        
        let index = sender.tag
        guard index < displayItems.count else {
            print("Index out of bounds!")
            return
        }
        let item = displayItems[index]
        
        switch item {
            
        case .bookmark(let model):
            print("Bookmark: \(model.bookmarksTxt)")
            
        case .segment(let segment):
            print("Segment: \(segment.startTime)-\(segment.endTime)")
            let playerVC = BottomSheetAudioPlayerVC()
            playerVC.url = segment.url
            playerVC.modalPresentationStyle = .pageSheet
            if let sheet = playerVC.sheetPresentationController {
                sheet.detents = [.medium()]
                sheet.prefersGrabberVisible = true
            }
            
            present(playerVC, animated: true)
            
        }
        
    }
    
    @objc func transcribeAllSegments() {
        aiLoader.show(in: view, msg: "Transcribing all bookmarks...")

        
        let segments = displayItems.compactMap { item -> BookmarkSegment? in
            if case .segment(let seg) = item, seg.transcription == nil || seg.summary == nil {
                return seg
            }
            return nil
        }

        let unprocessed = segments.filter { segment in
                let hasTranscript = BookmarkCacheManager.getTranscription(for: segment.identifiers)?.isEmpty == false
                let hasSummary = BookmarkCacheManager.getSummary(for: segment.identifiers)?.isEmpty == false
                return !hasTranscript || !hasSummary
            }

        
        guard !unprocessed.isEmpty else {
            print("All segments already transcribed and summarized.")
            self.aiLoader.dismiss()
            return
        }
        let group = DispatchGroup()
        
        for var segment in unprocessed {
            let id = segment.identifiers
            guard let url = segment.url else { continue }
           
            group.enter()
            TranscriptionAI.processAudio(fileURL: url) { result in
                if let result = result {
                    segment.transcription = result.transcription
                    segment.summary = result.summary
                    
                    BookmarkCacheManager.saveTranscription(result.transcription, for: id)
                    BookmarkCacheManager.saveSummary(result.summary, for: id)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.aiLoader.dismiss()
            self.tblV.reloadData()
            self.showAlert(title: "Done", message: "All bookmarks processed.")
        }
    }
    
    @objc func openCombinedTranscriptionSummary(_ sender: UIButton) {
        let index = sender.tag

        guard case .segment(var segment) = displayItems[index],
              let audioURL = segment.url else {
            return
        }
       let id = segment.identifiers
        print(id,"efefwd")
        if let cachedTranscription = BookmarkCacheManager.getTranscription(for: id),
           let cachedSummary = BookmarkCacheManager.getSummary(for: id) {
            
          
            segment.transcription = cachedTranscription
            segment.summary = cachedSummary
            
            self.presentCombinedSheet(
                transcription: cachedTranscription,
                summary: cachedSummary,
                timeRange: "\(self.formatTime(from: segment.startTime)) - \(self.formatTime(from: segment.endTime))"
            )
            
        } else {
          
            aiLoader.show(in: view, msg: "Fetching transcription & summary...")

            TranscriptionAI.processAudio(fileURL: audioURL) { [weak self] result in
                DispatchQueue.main.async {
                    self?.aiLoader.dismiss()
                    guard let self = self, let result = result else {
                        self?.showAlert(title: "Error", message: "Failed to process audio.")
                        return
                    }

                    segment.transcription = result.transcription
                    segment.summary = result.summary

        
                    BookmarkCacheManager.saveTranscription(result.transcription, for: id)
                    BookmarkCacheManager.saveSummary(result.summary, for: id)

                    self.presentCombinedSheet(
                        transcription: result.transcription,
                        summary: result.summary,
                        timeRange: "\(self.formatTime(from: segment.startTime)) - \(self.formatTime(from: segment.endTime))"
                    )
                    self.tblV.reloadData()
                }
            }
        }
    }
    
    func presentCombinedSheet(transcription: String, summary: String, timeRange: String) {
        let vc = TranscriptionSummaryVC()
        vc.timeRange = timeRange
        vc.summaryText = summary
        vc.transcriptionText = transcription
        vc.modalPresentationStyle = .pageSheet
        self.present(vc, animated: true)
    }
    
    @IBAction func btnCross_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
        
    }
    
    @IBAction func btnBack_Action(_ sender: Any) {
        
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnSort_Action(_ sender: UIButton) {
        
        self.topMenu.anchorView = btnSort
        self.topMenu.bottomOffset = CGPoint(x: -80, y: sender.bounds.height + 8)
        self.topMenu.textColor = .black
        self.topMenu.cornerRadius = 5.0
        self.topMenu.separatorColor = .clear
        self.topMenu.selectionBackgroundColor = .clear
        self.topMenu.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        self.topMenu.dataSource.removeAll()
        
        self.topMenu.dataSource.append(contentsOf: ["Time","Date"])
        let imagesArr = ["bx_time-five","calendar"]
        
        topMenu.cellNib = UINib(nibName: "DropDownCell", bundle: nil)
        topMenu.customCellConfiguration = { index, title, cell in
            
            guard let cell = cell as? MyCell1 else {
                return
            }
            cell.img1.image = UIImage(named: imagesArr[index])
            
        }
        
        topMenu.selectionAction = { [unowned self] (index, item) in
            if index == 0 {
                
                currentSortType = .byTime
                UserDefaults.standard.set("ByTime", forKey: "BookmarkSorting")
                
            }else{
                currentSortType = .byDate
                UserDefaults.standard.set("ByDate", forKey: "BookmarkSorting")
            }
            sortBookmarks()
        }
        
        self.topMenu.show()
        
        
    }
    
    func buttonTapped(index: Int, sender: UIButton) {
        print(index, "index")

        let item = displayItems[index]

        self.DownMenu.anchorView = sender
        self.DownMenu.direction = .any
        self.DownMenu.bottomOffset = CGPoint(x: -150, y: sender.bounds.height)
        self.DownMenu.topOffset = CGPoint(x: -150, y: sender.bounds.height)
        self.DownMenu.textColor = .black
        self.DownMenu.cornerRadius = 5.0
        self.DownMenu.separatorColor = .clear
        self.DownMenu.selectionBackgroundColor = .clear
        self.DownMenu.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        self.DownMenu.dataSource = ["Add/Edit Note", "Delete", "Cancel"]
        
        let imagesArr = ["Editicon", "Deleteicon", "Cancelicon"]
        
        DownMenu.cellNib = UINib(nibName: "DropDownCell", bundle: nil)
        DownMenu.customCellConfiguration = { index, title, cell in
            guard let cell = cell as? MyCell1 else { return }
            cell.img1.image = UIImage(named: imagesArr[index])
        }

        DownMenu.selectionAction = { [unowned self] (menuIndex, _) in
            switch item {
            case .bookmark(let bookmarkModel):
                switch menuIndex {
                case 0:
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "BookmarkPopUpVC") as! BookmarkPopUpVC
                    vc.playerstaus = PlayerManager.shared.isPlaying
                    vc.delegateBookmarkVC = self
                    vc.txt = bookmarkModel.bookmarksTxt
                    vc.index = index
                    vc.starStatus = bookmarkModel.isStar ?? false
                    self.addChild(vc)
                    vc.view.frame = self.view.frame
                    self.view.addSubview(vc.view)
                    self.view.bringSubviewToFront(vc.view)
                    vc.didMove(toParent: self)

                case 1:
                    showDeleteBookmarkAlert { confirmed in
                        if confirmed {
                            if let originalIndex = self.arrBookmarksNotes.firstIndex(where: { $0.indentifier == bookmarkModel.indentifier }) {
                                self.arrBookmarksNotes.remove(at: originalIndex)
                            }
                           
                            self.displayItems.remove(at: index)
                            self.tblV.reloadData()
                            self.saveBookMarksNotes()
                        }
                    }

                default: break
                }

            case .segment(let segment):
                switch menuIndex {
                case 0:
                    print("Edit Segment: \(segment.startTime) - \(segment.endTime)")

                case 1:
                    showDeleteBookmarkAlert { confirmed in
                        if confirmed {
                            if let originalIndex = self.arrMergedBookmarksNotes.firstIndex(where: { $0.identifiers == segment.identifiers }) {
                                self.arrMergedBookmarksNotes.remove(at: originalIndex)
                            }
    
                            self.displayItems.remove(at: index)
                            self.tblV.reloadData()
                        }
                    }

                default: break
                }
            }
        }

        self.DownMenu.show()
    }
    
    
    func MethodforPop(string: String) {
        let userDefaults = UserDefaults.standard
        
        if let savedData = userDefaults.object(forKey: (self.book.identifier ?? "")+"_bookmarks") as? Data {
            do{
                let savedBookmarks = try JSONDecoder().decode([BookmarksModel].self, from: savedData)
                if savedBookmarks.count > 0 {
                    self.arrBookmarksNotes = savedBookmarks
                }
                
                self.tblV.reloadData()
                
            } catch {
               
            }
        }
    }
    
    
    func sortBookmarks() {
        print(arrBookmarksNotes,"before sorting")
        switch currentSortType {
            
        case .byTime:
            
            let sortedArray = arrBookmarksNotes.sorted { compareTimes($0.time, $1.time) }
            self.arrBookmarksNotes = sortedArray
        case .byDate:
            let sortedArray = arrBookmarksNotes.sorted { compareDates($0.date, $1.date) }
            self.arrBookmarksNotes = sortedArray
        }
        self.tblV.reloadData()
        print(arrBookmarksNotes,"after sorting")
        
    }
    
    
    @IBAction func btnBookmark_shareAction(_ sender: Any) {
        guard let book = self.book else {return}
        
        if !MFMailComposeViewController.canSendMail() {
            showExportController(currentItem: book, bookmarks:  self.displayItems)
            return
        }
        
        self.showEmailExport(book: book, displayItems: self.displayItems)
        
    }
    
    func showExportController(currentItem: Book, bookmarks: [BookmarkDisplayItem]) {
        let provider = BookmarksActivityItemProvider(currentItem: currentItem, bookmarks: bookmarks)
        
        let shareController = UIActivityViewController(activityItems: [provider], applicationActivities: nil)
        
        if let popoverPresentationController = shareController.popoverPresentationController {
            popoverPresentationController.barButtonItem = navigationController?.topViewController?.navigationItem.rightBarButtonItem!
        }
        
        self.present(shareController, animated: true, completion: nil)
    }
    
    func showDeleteBookmarkAlert(completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: "Delete Bookmark?", preferredStyle: .alert)
        
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false)
        }
       
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            completion(true)
        }
        
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}


extension BookMarkVC {
    
    func compareTimes(_ time1: String, _ time2: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        
        if let date1 = formatter.date(from: time1),
           let date2 = formatter.date(from: time2) {
            return date1 < date2
        }
        
        return false
    }
    
    func compareDates(_ date1: String, _ date2: String) -> Bool {
        let result = compareDates(date1: date1, date2: date2)
        
        if let comparisonResult = result {
            switch comparisonResult {
            case .orderedAscending:
                print("Date 1 is earlier than Date 2")
                return true
            case .orderedDescending:
                print("Date 1 is after than Date 2")
                // return true
            case .orderedSame:
                print("Date 1 and Date 2 are the same")
            }
        }
        return false
    }
    
    func compareDates(date1: String, date2: String) -> ComparisonResult? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"
        
        if let date1 = dateFormatter.date(from: date1), let date2 = dateFormatter.date(from: date2) {
            return date1.compare(date2)
        } else {
            print("Invalid date format")
            return nil
        }
    }
    
}


extension BookMarkVC {
    func saveBookMarksNotes(){
        do {
            // 1
            let encodedData = try JSONEncoder().encode(self.arrBookmarksNotes)
            
            
            let userDefaults = UserDefaults.standard
            // 2
            userDefaults.set(encodedData, forKey: (self.book.identifier ?? "")+"_bookmarks")
            
            
        } catch {
            // Failed to encode Contact to Data
            
        }
        
    }
}



extension BookMarkVC {
    @objc func bookEnd(_ notification:Notification) {
        self.setPlayImage()
    }
    @objc private func onBookPause() {
        self.footerPlayButton.setImage(self.miniPlayImage, for: .normal)
        
    }
    @objc  func onBookStop(_ notification: Notification) {
        setPlayImage()
        
    }
    @objc  func onBookPlay() {
        
        setPlayImage()
        
    }
    @objc private func bookReady(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let book = userInfo["book"] as? Book else {
            return
        }
        
        currentBok = book
        setupMiniPlayer(book: book)
     
    }
    
    @objc private func bookChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let books = userInfo["books"] as? [Book],
              let currentBook = books.first else {
            return
        }
        currentBok = currentBook
        
        setupMiniPlayer(book: currentBook)
        PlayerManager.shared.play()
    }
    func setupMiniPlayer(book:Book){
        self.footerView.isHidden = false
        let title = book.title
        let author = book.author ?? "Unknown"
        self.footerImageView.image = book.artwork
        self.footerTitleLabel.text = (title ?? "") + " - " + author
        
        self.setPlayImage()
    }
    
    func setPlayImage(){
        let miniPlayImage = UIImage(named: "29")
        let miniPauseButton = UIImage(named: "21")
        if PlayerManager.shared.isPlaying {
            self.footerPlayButton.setImage(miniPauseButton, for: .normal)
            
        }else{
            self.footerPlayButton.setImage(miniPlayImage, for: .normal)
        }
        if PlayerManager.shared.miniPlayerIsHidden{
            
            self.footerView.isHidden = false
        }else{
            
            self.footerView.isHidden = false
        }
    }
    
}

extension BookMarkVC:TapOnOptions{
    func tapped(conditionValue: Int) {
        self.presentedViewController?.dismiss(animated: true)
        switch conditionValue {
        case 0:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "GetProfileVC") as! GetProfileVC
            self.navigationController?.pushViewController(vc, animated: true)
        case 1:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "SettingVC") as! SettingVC
            //self.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        case 2:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "BookMarkVC") as! BookMarkVC
            vc.dataBack = { t in
                PlayerManager.shared.forwardPressedCostomTime(t: t)
            }
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
    
}
extension String {
    public var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

extension UITableView {
    func addCorner5(){
        self.layer.cornerRadius = 15
        self.clipsToBounds = true
    }
    
    func addShadow5(){
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowRadius = 5
        self.layer.shadowOpacity = 1.0
        self.layer.shadowOffset = .zero
        self.layer.masksToBounds = true
    }
}
