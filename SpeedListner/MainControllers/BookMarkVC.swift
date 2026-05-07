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
//    @IBOutlet weak var transCribeBtn: UIButton!
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
            let defaults = UserDefaults.standard
            if defaults.object(forKey: "autoTranscribeWhileListening") == nil {
                defaults.set(true, forKey: "autoTranscribeWhileListening")
            }
            return defaults.bool(forKey: "autoTranscribeWhileListening")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "autoTranscribeWhileListening")
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        print("Table view connected: \(tblV != nil)")
        print("Table view data source: \(tblV.dataSource != nil)")
        print("Table view delegate: \(tblV.delegate != nil)")
        getBookmarks()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.showSpeedTrackTopBadge()
        if PlayerManager.shared.isPlaying {
            footerView.isHidden = false
        }
        guard let b = currentBok else { return }
        setupMiniPlayer(book: b)
        if !isAutoTranscribeEnabled{
            self.autoTranscribeChecked.setImage(UIImage(named: "ic_outline-check-box"), for: .normal)
        }
    }

    // MARK: - Setup
    
    func setupUI() {
        tblV.addCorner5()
        tblV.addShadow5()
        handleObservers()
        tblV.register(UINib(nibName: "BookMarkExpandCell", bundle: nil), forCellReuseIdentifier: "BookMarkExpandCell")
        tblV.register(UINib(nibName: "MergeBookMarkCell", bundle: nil), forCellReuseIdentifier: "MergeBookMarkCell")
        tblV.delegate = self
        tblV.dataSource = self
     //   transCribeBtn.addTarget(self, action: #selector(transcribeAllBtnAction), for: .touchUpInside)
        
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
        guard let book = currentBok else { return }
        self.book = book
        self.currentTitleBook.text = book.title
        let savedBookmarks = BookmarkManager.shared.loadBookmarks(for: book)
        applyBookmarks(savedBookmarks)

        BookmarkManager.shared.migrateLegacyBookmarksIfNeeded(for: book) { [weak self] migrated in
            guard let self = self else { return }
            self.applyBookmarks(migrated)
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

    private func applyBookmarks(_ bookmarks: [BookmarksModel]) {
        print("Saved bookmarks count: \(bookmarks.count)")

        if bookmarks.count > 0 {
            let validBookmarks = bookmarks.filter { bookmark in
                if let url = AudioClipUtils.resolveClipURL(for: bookmark) {
                    return FileManager.default.fileExists(atPath: url.path)
                }
                return false
            }

            print("Valid bookmarks count: \(validBookmarks.count)")
            self.arrBookmarksNotes = validBookmarks

            if validBookmarks.isEmpty {
                print("No valid bookmarks found - audio files might be missing")
                self.displayItems = []
                self.tblV.reloadData()
            } else {
                mergeAdjecntBookmarks()
            }
            updateBookmarkSummary()
        } else {
            print("No saved bookmarks data found")
            self.arrBookmarksNotes = []
            self.displayItems = []
            self.tblV.reloadData()
        }
    }
    
    
    private func updateBookmarkSummary() {
        let totalBookmarks = displayItems.count
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
                        self?.transcribeAllBtnAction()
                        self?.tblV.reloadData()
                        print("Table view should now show data")
                    } else {
                        self?.prepareDisplayItems()
                        self?.tblV.reloadData()
                        self?.transcribeAllBtnAction()
                        print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        )
    }
    
    private func prepareDisplayItems() {
        displayItems = []
   
        print("Bookmarks count: \(arrBookmarksNotes.count)")
        
        for bookmark in arrBookmarksNotes {
           
            if let _ = AudioClipUtils.resolveClipURL(for: bookmark) {
                displayItems.append(.bookmark(bookmark))
                print("Added bookmark: \(bookmark.timeStamp)")
            } else {
                print("Bookmark audio file not found: \(bookmark.timeStamp)")
            }
        }
        
        for segment in arrMergedBookmarksNotes {
            displayItems.append(.segment(BookmarkSegment(identifiers: segment.identifiers,
                                                       startTime: segment.startTime,
                                                       endTime: segment.endTime,
                                                       url: segment.url,
                                                       bookmarksTxt: BookmarkCacheManager.getNotes(for: segment.identifiers),
                                                         isStar: BookmarkCacheManager.getIsStar(for: segment.identifiers), date: segment.date)))
            print("Added segment: \(segment.startTime)-\(segment.endTime)")
        }
        
        print("Total display items: \(displayItems.count)")
        displayItems = buildDisplayItems(bookmarks: self.arrBookmarksNotes, segments: self.arrMergedBookmarksNotes)
        DispatchQueue.main.async {
            self.updateBookmarkSummary()
            self.tblV.reloadData()
            print("Table view reloaded")
        }
        
    }
    
    func buildDisplayItems(bookmarks: [BookmarksModel], segments: [BookmarkSegment]) -> [BookmarkDisplayItem] {
        var items: [BookmarkDisplayItem] = []

        var mergedTimestamps: Set<Double> = []
        for seg in segments {
            let range = seg.startTime...seg.endTime
            let included = bookmarks.filter { range.contains($0.timeStamp) }
            mergedTimestamps.formUnion(included.map { $0.timeStamp })
        }

        // 1) Add unmerged bookmarks only
        for bm in bookmarks {
            if !mergedTimestamps.contains(bm.timeStamp) {
                items.append(.bookmark(bm))
            }
        }

        // 2) Add merged segments
        for seg in segments {
            items.append(.segment(seg))
        }

        // 3) Sort by start time for display
        items.sort { lhs, rhs in
            switch (lhs, rhs) {
            case (.bookmark(let b1), .bookmark(let b2)):
                return b1.timeStamp < b2.timeStamp
            case (.bookmark(let b1), .segment(let s2)):
                return b1.timeStamp < s2.startTime
            case (.segment(let s1), .bookmark(let b2)):
                return s1.startTime < b2.timeStamp
            case (.segment(let s1), .segment(let s2)):
                return s1.startTime < s2.startTime
            }
        }

        return items
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
      
        print("Configuring cell for index: \(indexPath.row)")
           
           guard indexPath.row < displayItems.count else {
               print("ERROR: Index out of bounds")
               return UITableViewCell()
           }
           
           let item = displayItems[indexPath.row]
           print("Item type: \(item)")
        switch item {
        case .bookmark(let model):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "BookMarkExpandCell", for: indexPath) as? BookMarkExpandCell else {
                return UITableViewCell()
            }

            cell.delegate = self
            cell.selectionStyle = .none
            cell.optionBtn.tag = indexPath.row
            cell.detailtxt.text = model.bookmarksTxt
            
            var timestamp: TimeInterval
            let  ts = model.timeStamp
                   timestamp = ts
            let start = model.startTime ?? max(0, timestamp - 5.0)
            let end = model.endTime ?? (timestamp + 15.0)
            
        cell.bookmarkTimelbl.text = "\(formatTime(from: start)) ➔ \(formatTime(from: end)) on \(model.date)"
               
            cell.bottomView.isHidden = !(model.bookmarksTxt.count > 0 || model.isStar == true)
            cell.isStarBookMark.isHidden = !(model.isStar ?? false)
            cell.starBG.isHidden = !(model.isStar ?? false)
            cell.transSumryLable.layer.cornerRadius = 12
            cell.transSumryLable.clipsToBounds = true
            cell.playBtn.tag = indexPath.row
            cell.playBtn.addTarget(self, action: #selector(playBookmarkClip(_:)), for: .touchUpInside)
            cell.transcriptionBtn.tag = indexPath.row
            cell.transcriptionBtn.addTarget(self, action: #selector(openCombinedTranscriptionSummary(_:)), for: .touchUpInside)
            let bookmarkIdentifier = model.bookmarkId ?? "\(Int(model.timeStamp))"
            configureTranscriptionSummary(for: cell.transSumryLable, id: bookmarkIdentifier)
            return cell

        case .segment(let segment):
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "MergeBookMarkCell", for: indexPath) as? MergeBookMarkCell else {
                return UITableViewCell()
            }

            cell.delegate = self
            cell.selectionStyle = .none
            cell.optionBtn.tag = indexPath.row
            cell.playBtn.tag = indexPath.row
            cell.playBtn.addTarget(self, action: #selector(playBookmarkClip(_:)), for: .touchUpInside)
            cell.transcriptionBtn.tag = indexPath.row
            cell.transcriptionBtn.addTarget(self, action: #selector(openCombinedTranscriptionSummary(_:)), for: .touchUpInside)

        
            cell.bookmarkTimelbl.text = "\(formatTime(from: segment.startTime)) ➔ \(formatTime(from: segment.endTime)) on \(segment.date)"
           
            cell.detailtxt.text = segment.bookmarksTxt
       
            let isStar =  BookmarkCacheManager.getIsStar(for: segment.identifiers.replacingOccurrences(of: " ", with: "")) ?? false
            cell.bottomView.isHidden = !((segment.bookmarksTxt?.count ?? 0) > 0 || isStar == true)
            print(segment.identifiers,isStar,"isStar")
            cell.isStarBookMark.isHidden = !isStar
            cell.starBG.isHidden = !isStar
            cell.transSumryLable.layer.cornerRadius = 12
            cell.transSumryLable.clipsToBounds = true

            configureTranscriptionSummary(for: cell.transSumryLable, id: segment.identifiers)
            return cell
        }
    }

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return UITableView.automaticDimension
    }
   
    private func configureTranscriptionSummary(for label: UILabel, id: String) {
        if let _ = BookmarkCacheManager.getTranscription(for: id),
           let _ = BookmarkCacheManager.getSummary(for: id) {
            label.text = "Transcribed & Summarized"
            label.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1)
        } else {
            let underlineAttrString = NSAttributedString(
                string: "Transcribe & Summarize?",
                attributes: [
                    .underlineStyle: NSUnderlineStyle.single.rawValue,
                    .foregroundColor: UIColor.white,
                    .font: UIFont.systemFont(ofSize: 14, weight: .medium)
                ]
            )
            label.attributedText = underlineAttrString
            label.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.6)
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
    func deleteDisplayItem(at index: Int) {
        let item = displayItems[index]

        switch item {

        // ✅ SINGLE BOOKMARK DELETE (SAFE)
        case .bookmark(let bookmark):
            arrBookmarksNotes.removeAll {
                $0.timeStamp == bookmark.timeStamp
            }

        // ✅ SEGMENT DELETE (DELETE ONLY INCLUDED BOOKMARKS)
        case .segment(let segment):
            let start = segment.startTime
            let end = segment.endTime

            arrBookmarksNotes.removeAll {
                $0.timeStamp >= start && $0.timeStamp <= end
            }

            arrMergedBookmarksNotes.removeAll {
                $0.startTime == segment.startTime &&
                $0.endTime == segment.endTime
            }
        }

        saveBookMarksNotes()
        prepareDisplayItems()
        tblV.reloadData()
    }
    
    @IBAction private func tapMiniPlayerButton() {
        
    }
    
    @objc func play_pauseImgSet(_ notification:Notification){
        
    }
   
    
    
    @objc func handleAudioInterruptions(_ notification:Notification){
        
        
    }
    
    
     func transcribeAllBtnAction(){
        
        self.transcribeAllSegments()
        self.transcribeAllBookmarks()
    }
    
    @objc func autoTranscribeCheckAction(){
        if !isAutoTranscribeEnabled {
            self.autoTranscribeChecked.setImage(UIImage(named: "ic_outline-check-box-1"), for: .normal)
            isAutoTranscribeEnabled = true
            
        }else{
            self.autoTranscribeChecked.setImage(UIImage(named: "ic_outline-check-box"), for: .normal)
            isAutoTranscribeEnabled = false
        }
        
    }
    @IBAction func playAllBookmarksClips(_ sender:UIButton) {
        var urls: [URL] = []

        for item in displayItems {
            switch item {
            case .bookmark(let model):
                if let clipURL = AudioClipUtils.resolveClipURL(for: model) {
                    urls.append(clipURL)
                }
            case .segment(let segment):
                if let clipURL = segment.url {
                    urls.append(clipURL)
                }
            }
        }

        guard !urls.isEmpty else {
            showToast("No bookmark clips to play")
            return
        }

        let playerVC = BottomSheetAudioPlayerVC()
        playerVC.urls = urls.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) // sort if needed
        playerVC.modalPresentationStyle = .pageSheet
        if let sheet = playerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
        present(playerVC, animated: true)
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
            print("Bookmark: \(model.audioClipPath)")
          
            let playerVC = BottomSheetAudioPlayerVC()
            playerVC.url = AudioClipUtils.resolveClipURL(for: model)
 //model.audioClipPath
            playerVC.modalPresentationStyle = .pageSheet
            if let sheet = playerVC.sheetPresentationController {
                sheet.detents = [.medium()]
                sheet.prefersGrabberVisible = true
            }
            
            present(playerVC, animated: true)
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
    
    @objc func transcribeAllBookmarks() {
        aiLoader.show(in: view, msg: "Transcribing all bookmarks...")

        
        let bookmarks = displayItems.compactMap { item -> BookmarksModel? in
            if case .bookmark(let bookMark) = item, bookMark.transcription == nil || bookMark.summary == nil {
                return bookMark
            }
            return nil
        }

        let unprocessed = bookmarks.filter { bookmark in
                let id = bookmark.bookmarkId ?? "\(Int(bookmark.timeStamp))"
                let hasTranscript = BookmarkCacheManager.getTranscription(for: id)?.isEmpty == false
                let hasSummary = BookmarkCacheManager.getSummary(for: id)?.isEmpty == false
                return !hasTranscript || !hasSummary
            }

        
        guard !unprocessed.isEmpty else {
            print("All segments already transcribed and summarized.")
            self.aiLoader.dismiss()
            return
        }
        let group = DispatchGroup()
        
        for var bookmark in unprocessed {
            let id = bookmark.bookmarkId ?? "\(Int(bookmark.timeStamp))"
            guard let url = AudioClipUtils.resolveClipURL(for: bookmark) else { continue }
           
            group.enter()
            TranscriptionAI.processAudio(fileURL: url) { result in
                if let result = result {
                    bookmark.transcription = result.transcription
                    bookmark.summary = result.summary
                    
                    BookmarkCacheManager.saveTranscription(result.transcription, for: id)
                    BookmarkCacheManager.saveSummary(result.summary, for: id)
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            self.aiLoader.dismiss()
            self.tblV.reloadData()
            print("All bookmarks processed.")
        //    self.showAlert(title: "Done", message: "All bookmarks processed.")
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
            print("All bookmarks processed.")
        //    self.showAlert(title: "Done", message: "All bookmarks processed.")
        }
    }
    
    
    
    @objc func openCombinedTranscriptionSummary(_ sender: UIButton) {
        let index = sender.tag
        guard index < displayItems.count else {
            print("Index out of bounds!")
            return
        }

        switch displayItems[index] {
        case .bookmark(let model):
            let id = model.bookmarkId ?? "\(Int(model.timeStamp))"
            guard let url = AudioClipUtils.resolveClipURL(for: model) else { return }
            let timeRange = "\(model.time) - \(model.date)"

            handleTranscription(for: id, audioURL: url, fallbackTranscription: model.transcription, fallbackSummary: model.summary, timeRange: timeRange)

        case .segment(let segment):
            let id = segment.identifiers
            guard let url = segment.url else { return }
            let timeRange = "\(formatTime(from: segment.startTime)) - \(formatTime(from: segment.endTime))"

            handleTranscription(for: id, audioURL: url, fallbackTranscription: segment.transcription, fallbackSummary: segment.summary, timeRange: timeRange)
        }
    }
    
    private func handleTranscription(for id: String, audioURL: URL, fallbackTranscription: String?, fallbackSummary: String?, timeRange: String) {
        if let cachedTranscription = BookmarkCacheManager.getTranscription(for: id),
           let cachedSummary = BookmarkCacheManager.getSummary(for: id) {
            presentCombinedSheet(transcription: cachedTranscription, summary: cachedSummary, timeRange: timeRange)
            return
        }

        aiLoader.show(in: view, msg: "Fetching transcription & summary...")
        
        TranscriptionAI.processAudio(fileURL: audioURL) { [weak self] result in
            DispatchQueue.main.async {
                self?.aiLoader.dismiss()
                guard let self = self, let result = result else {
                    self?.showAlert(title: "Error", message: "Failed to process audio.")
                    return
                }

                BookmarkCacheManager.saveTranscription(result.transcription, for: id)
                BookmarkCacheManager.saveSummary(result.summary, for: id)

                self.presentCombinedSheet(transcription: result.transcription, summary: result.summary, timeRange: timeRange)
                self.tblV.reloadData()
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
        
        self.topMenu.dataSource.append(contentsOf: ["Chronological ","Created"])
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
                    vc.displayItems = displayItems
                    vc.starStatus = bookmarkModel.isStar ?? false
                    self.addChild(vc)
                    vc.view.frame = self.view.frame
                    self.view.addSubview(vc.view)
                    self.view.bringSubviewToFront(vc.view)
                    vc.didMove(toParent: self)

                case 1:
                    
                    showDeleteBookmarkAlert { confirmed in
                        if confirmed {
                            self.deleteDisplayItem(at: index)
                        }
                    }
//                    showDeleteBookmarkAlert { confirmed in
//                        if confirmed {
//                            if let originalIndex = self.arrBookmarksNotes.firstIndex(where: { $0.indentifier == bookmarkModel.indentifier }) {
//                                self.arrBookmarksNotes.remove(at: originalIndex)
//                            }
//                           
//                            self.displayItems.remove(at: index)
//                            self.tblV.reloadData()
//                            self.saveBookMarksNotes()
//                        }
//                    }

                default: break
                }

            case .segment(let segment):
                switch menuIndex {
                case 0:
                    print("Edit Segment: \(segment.startTime) - \(segment.endTime)")
                    let vc = self.storyboard?.instantiateViewController(withIdentifier: "BookmarkPopUpVC") as! BookmarkPopUpVC
                    vc.playerstaus = PlayerManager.shared.isPlaying
                    vc.delegateBookmarkVC = self
                    vc.txt = segment.bookmarksTxt
                    vc.index = index
                    vc.displayItems = displayItems
                    vc.starStatus = segment.isStar ?? false
                    self.addChild(vc)
                    vc.view.frame = self.view.frame
                    self.view.addSubview(vc.view)
                    self.view.bringSubviewToFront(vc.view)
                    vc.didMove(toParent: self)
                    
                case 1:
//                    showDeleteBookmarkAlert { confirmed in
//                        if confirmed {
//                            if let originalIndex = self.arrMergedBookmarksNotes.firstIndex(where: { $0.identifiers == segment.identifiers }) {
//                                self.arrMergedBookmarksNotes.remove(at: originalIndex)
//                            }
//                            self.displayItems.remove(at: index)
//                            self.tblV.reloadData()
//                        }
//                    }
                    showDeleteBookmarkAlert { confirmed in
                        if confirmed {
                            self.deleteDisplayItem(at: index)
                        }
                    }
                default: break
                }
            }
        }

        self.DownMenu.show()
    }
    
    
    func MethodforPop(string: String) {
        getBookmarks()
    }
    
    
    func sortBookmarks() {
       // print(arrBookmarksNotes,"before sorting")
        switch currentSortType {
            
        case .byTime:
            
            let sortedArray = arrBookmarksNotes.sorted {compareTimes($0.time, $1.time) }
            self.arrBookmarksNotes = sortedArray
        case .byDate:
            let sortedArray = arrBookmarksNotes.sorted { compareDates($0.date, $1.date) }
            self.arrBookmarksNotes = sortedArray
        }
        self.tblV.reloadData()
      //  print(arrBookmarksNotes,"after sorting")
        
    }
    
    
    @IBAction func btnBookmark_shareAction(_ sender: UIButton) {
        guard let book = self.book else {return}
        
        let sheet = UIAlertController(title: nil,
                                              message: nil,
                                              preferredStyle: .actionSheet)

                // Send via Email
                let emailAction = UIAlertAction(title: "Send via Email", style: .default) { [weak self] _ in
                    self?.showEmailExport(book: book, displayItems: self?.displayItems ?? [])
                
                }
                sheet.addAction(emailAction)

                // Send by Other App
                let otherAction = UIAlertAction(title: "Send by Other App", style: .default) { [weak self] _ in
                    self?.showExportController(currentItem: book, bookmarks:  self?.displayItems ?? [])
                }
                sheet.addAction(otherAction)

                // Cancel
                sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

                // iPad: anchor properly
        if let popover = sheet.popoverPresentationController, let sourceView = self.view {
                    popover.sourceView = sourceView
                    popover.sourceRect = CGRect(x: sourceView.bounds.midX, y: sourceView.bounds.midY, width: 1, height: 1)
                    popover.permittedArrowDirections = []
                }

                self.present(sheet, animated: true, completion: nil)
//        if !MFMailComposeViewController.canSendMail() {
//            showExportController(currentItem: book, bookmarks:  self.displayItems)
//            return
//        }
//
  //      showExportController(currentItem: book, bookmarks:  self.displayItems)
       // self.showEmailExport(book: book, displayItems: self.displayItems)
        
    }
    
    func showExportController(currentItem: Book, bookmarks: [BookmarkDisplayItem]) {
            let provider = BookmarksActivityItemProvider(currentItem: currentItem, bookmarks: bookmarks)
            
            let shareController = UIActivityViewController(activityItems: [provider], applicationActivities: nil)
            
            if let popoverPresentationController = shareController.popoverPresentationController {
                if let barButton = navigationController?.topViewController?.navigationItem.rightBarButtonItem {
                    popoverPresentationController.barButtonItem = barButton
                } else if let presentingVC = self.presentingViewController as? UIViewController, let senderButton = presentingVC.view.subviews.compactMap({ $0 as? UIButton }).first {
                    popoverPresentationController.sourceView = senderButton
                    popoverPresentationController.sourceRect = senderButton.bounds
                } else {
                    popoverPresentationController.sourceView = self.view
                    popoverPresentationController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 1, height: 1)
                    popoverPresentationController.permittedArrowDirections = []
                }
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
        dateFormatter.dateFormat = "MM/dd/yyyy hh:mm a"
        
        if let d1 = dateFormatter.date(from: date1), let d2 = dateFormatter.date(from: date2) {
            return d1.compare(d2)
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
