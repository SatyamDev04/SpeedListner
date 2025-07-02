//
//  BookMarkVC.swift
//  SpeedListners
//
//  Created by ravi on 19/08/22.
//

import UIKit
import DropDown

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

    // MARK: - Properties
    let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
    let topMenu = DropDown()
    let DownMenu = DropDown()
    lazy var dropDowns: [DropDown] = { [topMenu, DownMenu] }()

    var arrBookmarksNotes = [BookmarksModel]()
    var arrMergedBookmarksNotes = [BookmarkSegment]()
    var book: Book!
    var dataBack: (_ t: Double) -> () = { _ in }

    let miniPlayImage = UIImage(named: "29")
    let miniPauseButton = UIImage(named: "21")
    var currentSortType: SortType = .byTime
    var currentPlayingStatus: Bool = false
    let aiLoader = AILoaderView()

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
                        self?.tblV.reloadData()
                    } else {
                        print("Error: \(error?.localizedDescription ?? "Unknown error")")
                    }
                }
            }
        )
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
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 1:
            return arrBookmarksNotes.count
        case 0:
            return arrMergedBookmarksNotes.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
       
        
        if indexPath.section == 1 {
            let cell = tblV.dequeueReusableCell(withIdentifier: "BookMarkExpandCell") as! BookMarkExpandCell
            cell.delegate = self
            cell.selectionStyle = .none
            cell.bottomView.isHidden = true
                   cell.delegate = self
                   cell.optionBtn.tag = indexPath.row
                   cell.selectionStyle = .none
                   cell.detailtxt.text = arrBookmarksNotes[indexPath.row].bookmarksTxt
           cell.bookmarkTimelbl.text = arrBookmarksNotes[indexPath.row].time + " - " + arrBookmarksNotes[indexPath.row].date
                   cell.bookmarkBtn.tag = indexPath.row
                   cell.bookmarkBtn.addTarget(self, action: #selector(bookmarkTapButton(_:)), for: .touchUpInside)
                   if (arrBookmarksNotes[indexPath.row].bookmarksTxt.count ) > 0 || arrBookmarksNotes[indexPath.row].isStar == true{
                       cell.bottomView.isHidden = false
                   }
                   if  arrBookmarksNotes[indexPath.row].isStar ?? false {
                       cell.isStarBookMark.isHidden = false
                       cell.starBG.isHidden = false
                   }else{
                       cell.isStarBookMark.isHidden = true
                       cell.starBG.isHidden = true
                   }
                   
                   return cell
            
        } else {
            
            // Merged MergeBookMarkCell
            let cell = tblV.dequeueReusableCell(withIdentifier: "MergeBookMarkCell") as! MergeBookMarkCell
            cell.selectionStyle = .none
            let segment = arrMergedBookmarksNotes[indexPath.row]
            cell.bookmarkTimelbl.text = "\(formatTime(from: segment.startTime))" + " - " + "\(formatTime(from: segment.endTime))"
            cell.playBtn.tag = indexPath.row
            cell.playBtn.addTarget(self, action: #selector(playBookmarkClip(_:)), for: .touchUpInside)
            cell.transcriptionBtn.tag = indexPath.row
            cell.transcriptionBtn.addTarget(self, action: #selector(trancripClip(_:)), for: .touchUpInside)
            
            cell.emailBtn.tag = indexPath.row
            cell.emailBtn.addTarget(self, action: #selector(summriseClip(_:)), for: .touchUpInside)
    
            
            return cell
        }
        
      
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: 40))
        headerView.backgroundColor = .white
        
        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        titleLabel.textColor = .white
        titleLabel.text = section == 1 ? "Individual Bookmarks" : "Merged Segments"
        headerView.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            titleLabel.topAnchor.constraint(equalTo: headerView.topAnchor, constant: 8),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -8)
        ])
        
       
        headerView.layer.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1)
    
        return headerView
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
        let t = self.arrBookmarksNotes[sender.tag].timeStamp
        self.dataBack(t)
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction private func tapMiniPlayerButton() {
        
    }
    
    @objc func play_pauseImgSet(_ notification:Notification){
        
    }
   
    
    
    @objc func handleAudioInterruptions(_ notification:Notification){
        
        
    }
    
    @objc func playBookmarkClip(_ sender:UIButton){
        let playerVC = BottomSheetAudioPlayerVC()
        playerVC.url = arrMergedBookmarksNotes[sender.tag].url
        playerVC.modalPresentationStyle = .pageSheet

        if let sheet = playerVC.sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }

        present(playerVC, animated: true)
    }
    
    @objc func trancripClip(_ sender: UIButton) {
        let index = sender.tag
        guard let audioURL = arrMergedBookmarksNotes[index].url else { return }

        if let text = arrMergedBookmarksNotes[index].transcription, !text.isEmpty {
            presentTranscriptionSheet(with: text)
        } else {
            aiLoader.show(in: view, msg: "AI is Fetching Transcription for your bookmarks...")
            TranscriptionAI.transcribeLocalAudio(fileURL: audioURL) { [weak self] transcription in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.aiLoader.dismiss()
                    if let transcription = transcription {
                        self.arrMergedBookmarksNotes[index].transcription = transcription
                        self.presentTranscriptionSheet(with: transcription)
                    } else {
                        self.showAlert(title: "Error", message: "Failed to fetch transcription.")
                    }
                }
            }
        }
    }

    @objc func summriseClip(_ sender: UIButton) {
        let index = sender.tag
        guard let audioURL = arrMergedBookmarksNotes[index].url else { return }

        func summarize(text: String) {
            aiLoader.show(in: view, msg: "AI is summarizing Transcription for your bookmarks...")
            TranscriptionAI.getSummary(from: text) { [weak self] summary in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.aiLoader.dismiss()
                    if let summary = summary {
                        self.arrMergedBookmarksNotes[index].summary = summary
                        self.presentSummaryBottomSheet(with: summary, from: self)
                    } else {
                        self.showAlert(title: "Error", message: "Failed to summarize transcription.")
                    }
                }
            }
        }

        if let text = arrMergedBookmarksNotes[index].transcription, !text.isEmpty {
            if let summary = arrMergedBookmarksNotes[index].summary, !summary.isEmpty {
                self.presentSummaryBottomSheet(with: summary, from: self)
            }else{
                summarize(text: text)
            }
          
        } else {
            aiLoader.show(in: view, msg: "AI is Fetching Transcription for your bookmarks...")
            TranscriptionAI.transcribeLocalAudio(fileURL: audioURL) { [weak self] transcription in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.aiLoader.dismiss()
                    if let transcription = transcription {
                        self.arrMergedBookmarksNotes[index].transcription = transcription
                        if let summary = self.arrMergedBookmarksNotes[index].summary, !summary.isEmpty {
                            self.presentSummaryBottomSheet(with: summary, from: self)
                        }else{
                            summarize(text: transcription)
                        }
                    } else {
                        self.showAlert(title: "Error", message: "Failed to transcribe.")
                    }
                }
            }
        }
    }
    func presentSummaryBottomSheet(with summary: String, from vc: UIViewController) {
        let bottomSheet = SummaryBottomSheetVC()
        bottomSheet.summaryText = summary
        if let sheet = bottomSheet.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        vc.present(bottomSheet, animated: true)
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
        //        self.topMenu.borderWidth = 1
        //        self.topMenu.borderColor = #colorLiteral(red: 0.3842016757, green: 0.2161925137, blue: 0.7387148142, alpha: 1)
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
            cell.img1.image = UIImage(named: imagesArr[index])// UIImage(systemName: imagesArr[index])
            // cell.lbltitle.text = aArr[index]
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
        print(index,"index")
        
        self.DownMenu.anchorView = sender
        self.DownMenu.direction = .any
        self.DownMenu.bottomOffset = CGPoint(x: -150, y: sender.bounds.height  )
        self.DownMenu.topOffset = CGPoint(x: -150, y: sender.bounds.height )
        self.DownMenu.textColor = .black
        self.DownMenu.cornerRadius = 5.0
        self.DownMenu.separatorColor = .clear
        self.DownMenu.selectionBackgroundColor = .clear
        self.DownMenu.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        self.DownMenu.dataSource.removeAll()
        
        self.DownMenu.dataSource.append(contentsOf: ["Add/Edit Note","Delete Bookmark"," Cancel"])
        let imagesArr = ["Editicon","Deleteicon","Cancelicon"]
        
        DownMenu.cellNib = UINib(nibName: "DropDownCell", bundle: nil)
        DownMenu.customCellConfiguration = { index, title, cell in
            
            guard let cell = cell as? MyCell1 else {
                return
            }
            cell.img1.image = UIImage(named: imagesArr[index]) // UIImage(systemName: imagesArr[index])
            
        }
        DownMenu.selectionAction = { [unowned self] (index1, item) in
            if index1 == 0 {
                print("add-edit",index)
                
                let vc: BookmarkPopUpVC = self.storyboard?.instantiateViewController(withIdentifier: "BookmarkPopUpVC") as! BookmarkPopUpVC
                
                vc.playerstaus = PlayerManager.shared.isPlaying
                vc.delegateBookmarkVC = self
                vc.txt = self.arrBookmarksNotes[index].bookmarksTxt
                vc.index = index
                vc.starStatus = self.arrBookmarksNotes[index].isStar ?? false
                self.addChild(vc)
                vc.view.frame = self.view.frame
                self.view.addSubview(vc.view)
                self.view.bringSubviewToFront(vc.view)
                vc.didMove(toParent: self)
                
                
            }else if index1 == 1{
                showDeleteBookmarkAlert { confirmed in
                    if confirmed {
                        print("Delete",index)
                        self.arrBookmarksNotes.remove(at: index)
                        self.tblV.reloadData()
                        self.saveBookMarksNotes()
                    } else {
                        print("Cancel",index)
                        
                    }
                }
                
            }else{
                print("Cancel",index)
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
                // Failed to convert Data to Contact
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
        self.showExportController(currentItem: book, bookmarks: self.arrBookmarksNotes)
    }
    
    func showExportController(currentItem: Book, bookmarks: [BookmarksModel]) {
        let provider = BookmarksActivityItemProvider(currentItem: currentItem, bookmarks: bookmarks)
        
        let shareController = UIActivityViewController(activityItems: [provider], applicationActivities: nil)
        
        if let popoverPresentationController = shareController.popoverPresentationController {
            popoverPresentationController.barButtonItem = navigationController?.topViewController?.navigationItem.rightBarButtonItem!
        }
        
        self.present(shareController, animated: true, completion: nil)
    }
    
    func showDeleteBookmarkAlert(completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(title: nil, message: "Delete Bookmark?", preferredStyle: .alert)
        
        // Cancel action
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completion(false) // User cancelled
        }
        
        // Delete action
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { _ in
            completion(true) // User confirmed deletion
        }
        
        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        
        self.present(alert, animated: true, completion: nil)
        
    }
    private func presentTranscriptionSheet(with text: String) {
        let sheetVC = TranscriptionBottomSheet(transcription: text)
        if let sheet = sheetVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        self.present(sheetVC, animated: true)
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

final class BookmarksActivityItemProvider: UIActivityItemProvider {
    
    let currentItem: Book
    let bookmarks: [BookmarksModel]
    
    init(currentItem: Book, bookmarks: [BookmarksModel]) {
        self.currentItem = currentItem
        self.bookmarks = bookmarks
        super.init(placeholderItem: URL(fileURLWithPath: "placeholder.txt"))
    }
    
    public override func activityViewController(
        _ activityViewController: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        let t = currentItem.title
        
        let fileTitle = "bookmarks-" + " \(t ?? "").txt"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileTitle)
        
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
            
            let contentsData = parseBookmarksData()
            FileManager.default.createFile(atPath: fileURL.path, contents: contentsData)
        } catch {
            return nil
        }
        
        return fileURL
    }
    func formatTime(_ time:Int) -> String {
        let hours = Int(time / 3600)
        
        let remaining = Float(time - (hours * 3600))
        
        let minutes = Int(remaining / 60)
        
        let seconds = Int(remaining - Float(minutes * 60))
        
        var formattedTime = String(format:"%02d:%02d", minutes, seconds)
        if hours > 0 {
            formattedTime = String(format:"%02d:"+formattedTime, hours)
        }
        
        return formattedTime
    }
    func parseBookmarksData() -> Data? {
        var fileContents = ""
        
        for bookmark in bookmarks {
            
            let chapterTime = bookmark.time
            let chapterdate = bookmark.date
            let formattedTime = self.formatTime(Int(currentItem.duration))
            fileContents += "\("Bookmark".localized): \(chapterTime)\n"
            fileContents += "\("Date".localized): \(chapterdate)\n"
            fileContents += "\("Book Length".localized): \(formattedTime)\n"
            if bookmark.isStar ?? false {
                fileContents += "\("Starred?".localized): \("******************************")\n"
            }else{
                fileContents += "\("Starred?".localized): \("")\n"
            }
            let note = bookmark.bookmarksTxt
            fileContents += "\("Note".localized): \(note)\n"
            
            fileContents += "------------------\n"
        }
        
        return fileContents.data(using: .utf8)
    }
    
    public override func activityViewControllerPlaceholderItem(
        _ activityViewController: UIActivityViewController
    ) -> Any {
        return URL(fileURLWithPath: "placeholder.txt")
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
        // setupMiniPlayer(book: book)
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
