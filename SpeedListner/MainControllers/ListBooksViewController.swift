//
//  ListBooksViewController.swift
//  SpeedListner
// Created by Satyam Dwivedi on 16/06/23.


import UIKit
import MediaPlayer
import DropDown
import UserNotifications

var currentBok:Book!

class ListBooksViewController: UIViewController, UIGestureRecognizerDelegate {
    

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerImageView: UIImageView!
    @IBOutlet weak var footerTitleLabel: UILabel!
    @IBOutlet weak var footerPlayButton: UIButton!
    @IBOutlet weak var collecV: UICollectionView!
    @IBOutlet weak var tblDrop: UITableView!
    @IBOutlet weak var btnBookshowStatus: UIButton!
    @IBOutlet weak var searchTxt: UITextField!
    @IBOutlet weak var crossBtnSearch: UIButton!
    @IBOutlet weak var sortByTxt: UILabel!
    @IBOutlet weak var searchTblV: UITableView!
    @IBOutlet weak var searchTblVH: NSLayoutConstraint!
    
    private var keyboardHideWorkItem: DispatchWorkItem?
    var debounceWorkItem: DispatchWorkItem?
    var checked = false
    var recentChecked = true
    let cloudFilePicker = CloudFilePicker()
    var selectedIndices = Set<IndexPath>()
    var isSelectionModeEnabled = false
    private var bottomSheetVC: BottomSheetViewController?
    private var isBottomSheetVisible = false
    let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
    
    let miniPlayImage = UIImage(named: "29")
    let miniPauseButton = UIImage(named: "21")
    var AlphabetArr = (65...90).map { String(UnicodeScalar($0))}
    
    var cuBook:Book?
    var selectedTxt = ""
    let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    
    let refreshControl = UIRefreshControl()
    let topMenu = DropDown()
    let sortMenu = DropDown()
    var library: Library!
    var items : [LibraryItem] = []{
        didSet{
            self.tableView.reloadData()
        }
    }
    var t_items = [LibraryItem]()
    
    let queue = OperationQueue()
    var loading = LoadingView()
    var playlist: Playlist!
    
    
    var filteredBooks: [Book] = []
    var matchedPlaylists: [Playlist] = []
    var isSearching = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        handleAppearanceMode()
        setupUserCheckedStatus()
        setupSearchFieldDelegate()
        setupPullToRefresh()
        setupFooterView()
        setupRemoteControlListeners()
        registerNotifications()
        handleUserDetails()
        loadPreviousBook()
        setupBottomSheet()
    }
    
    
    @objc func loadLibrary() {

        self.library = NewDataMannagerClass.getLibrary()
        self.items = self.library.items?.array as? [LibraryItem] ?? []

        let playlists = self.items.compactMap { $0 as? Playlist }

        //  FILTER BOOKS WITH MISSING FILES HERE
        let books = self.items
            .compactMap { $0 as? Book }
            .filter { isAudioFileAvailable(book: $0) }

        // Sort playlists
        let sortedPlaylists = playlists.sorted {
            ($0.title ?? "")
                .localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
        }

        // Sort books
        let sortedBooks: [Book]
        switch UserDetail.shared.getSortBy() {

        case "0":
            sortedBooks = books.sorted {
                ($0.uploadTime ?? Date.distantFuture) >
                ($1.uploadTime ?? Date.distantPast)
            }
            self.sortByTxt.text = "Newest Upload"

        case "1":
            sortedBooks = books.sorted {
                ($0.uploadTime ?? Date.distantFuture) <
                ($1.uploadTime ?? Date.distantPast)
            }
            self.sortByTxt.text = "Oldest Upload"

        case "2":
            sortedBooks = books.sorted {
                ($0.recentPlayTime ?? .distantPast) >
                ($1.recentPlayTime ?? .distantPast)
            }
            self.sortByTxt.text = "Recently Played"

        case "3":
            sortedBooks = books.sorted {
                ($0.title ?? "")
                    .localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
            }
            self.sortByTxt.text = "Alphabetical"

        default:
            sortedBooks = books
        }

        // Combine playlists + valid books only
        self.items = sortedPlaylists + sortedBooks
        self.t_items = self.items

        if !checked {
            btnBookshowStatus.setImage(
                UIImage(named: "ic_outline-check-box-1"),
                for: .normal
            )
        } else {
            btnBookshowStatus.setImage(
                UIImage(named: "ic_outline-check-box"),
                for: .normal
            )
        }

        DispatchQueue.main.async {
            self.tableView.reloadData()
            self.refreshControl.endRefreshing()
        }
    }
    
    func isAudioFileAvailable(book: Book) -> Bool {
        return FileManager.default.fileExists(atPath: book.fileURL.path)
    }
    
    // MARK: - Duplicate check helper (reusable)
    private func checkDuplicateFor(processedURL: URL, completion: @escaping (Book?) -> Void) {
        
        let asset = AVAsset(url: processedURL)
        let incomingTitle = AVMetadataItem.metadataItems(from: asset.metadata, withKey: AVMetadataKey.commonKeyTitle, keySpace: AVMetadataKeySpace.common).first?.value?.copy(with: nil) as? String ??  processedURL.deletingPathExtension().lastPathComponent
        
        let incomingDuration = CMTimeGetSeconds(asset.duration)

         let library = NewDataMannagerClass.getLibrary()
        
        let items = library.items?.array as? [LibraryItem] ?? []

        let existingBooks = items.compactMap { $0 as? Book }

       
        func normalize(_ s: String) -> String {
            return s
                .lowercased()
                .replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let normalizedIncoming = normalize(incomingTitle)

        if let duplicate = existingBooks.first(where: { book in
            let normalizedExisting = normalize(book.title ?? "")
            let sameTitle = normalizedIncoming.contains(normalizedExisting) || normalizedExisting.contains(normalizedIncoming)
            let sameDuration = abs(book.duration - incomingDuration) < 2
            return sameTitle && sameDuration
        }) {
            completion(duplicate)
        } else {
            completion(nil)
        }
    }

    @objc func loadformAppDelegate(){
        self.loading.showActivityLoading(uiView: self.view)
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
            print("timer runnnig")

            self.library = NewDataMannagerClass.getLibrary()
            NewDataMannagerClass.notifyPendingFiles()
            if self.items.count != (self.library.items?.array as? [LibraryItem] ?? []).count{
                t.invalidate()
            }
            self.items = self.library.items?.array as? [LibraryItem] ?? []
            self.t_items = self.items

            self.tableView.reloadData()
            //  self.emptyListContainerView.isHidden = !self.items.isEmpty
            self.refreshControl.endRefreshing()
            self.loading.hideActivityLoading(uiView: self.view)

            
        }
    }

    @objc func openURL(_ notification: Notification) {

        guard let userInfo = notification.userInfo,
              let fileURL = userInfo["fileURL"] as? URL else {
            return
        }

        let destinationFolder = NewDataMannagerClass.getProcessedFolderURL()

        NewDataMannagerClass.processFile(at: fileURL, destinationFolder: destinationFolder) { (processedURL) in
            guard let processedURL = processedURL else {
                self.loadformAppDelegate()
                return
            }

            self.checkDuplicateFor(processedURL: processedURL) { duplicateBook in
                DispatchQueue.main.async {
                    if let dup = duplicateBook {
                       
                        let alert = UIAlertController(
                            title: "Duplicate Audiobook",
                            message: "There is already an audiobook named '\(dup.title ?? "Unknown")' in your library. Do you still want to upload this audiobook?",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                        
                            self.loadformAppDelegate()
                        }))
                        alert.addAction(UIAlertAction(title: "Upload Anyway", style: .default, handler: { _ in
                            // Proceed exactly as before
                            let bookUrl = BookURL(original: fileURL, processed: processedURL)
                            self.loadFile(urls: [bookUrl])
                        }))
                         self.present(alert, animated: true, completion: nil)
                     
                    } else {
                       
                        let bookUrl = BookURL(original: fileURL, processed: processedURL)
                        self.loadFile(urls: [bookUrl])
                    }
                }
            }
        }
    }
    
//    @objc func loadformAppDelegate(){
//        
//        self.loading.showActivityLoading(uiView: self.view)
//        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { t in
//            print("timer runnnig")
//            
//            self.library = NewDataMannagerClass.getLibrary()
//            NewDataMannagerClass.notifyPendingFiles()
//            if self.items.count != (self.library.items?.array as? [LibraryItem] ?? []).count{
//                t.invalidate()
//            }
//            self.items = self.library.items?.array as? [LibraryItem] ?? []
//            self.t_items = self.items
//            
//            self.tableView.reloadData()
//          //  self.emptyListContainerView.isHidden = !self.items.isEmpty
//            self.refreshControl.endRefreshing()
//            self.loading.hideActivityLoading(uiView: self.view)
//            
//        }
//    }
//    
//    @objc func openURL(_ notification: Notification) {
//        
//        guard let userInfo = notification.userInfo,
//              let fileURL = userInfo["fileURL"] as? URL else {
//            return
//        }
//        let destinationFolder = NewDataMannagerClass.getProcessedFolderURL()
//        
//        NewDataMannagerClass.processFile(at: fileURL, destinationFolder: destinationFolder) { (processedURL) in
//            guard let processedURL = processedURL else {
//                self.loadformAppDelegate()
//                return
//            }
//            
//            let bookUrl = BookURL(original: fileURL, processed: processedURL)
//            self.loadFile(urls: [bookUrl])
//        }
//    }
    
    
    func loadFile(urls: [BookURL]) {
        self.queue.addOperation {
            NewDataMannagerClass.insertBooks(from: urls, into: nil, or: self.library) {
                NewDataMannagerClass.saveContext()
                self.loadLibrary()
            }
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.showSpeedTrackTopBadge()
        self.checked = UserDefaults.standard.object(forKey: "checked") as? Bool ?? false
        self.loadLibrary()
        if PlayerManager.shared.isPlaying {
            self.footerView.isHidden = false
            onBookPlay()
        }
        
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        UIApplication.shared.endReceivingRemoteControlEvents()
    }
    
    
    func setPlayImage(){
        
        if PlayerManager.shared.isPlaying {
            self.footerPlayButton.setImage(self.miniPauseButton, for: .normal)
            
        }else{
            self.footerPlayButton.setImage(self.miniPlayImage, for: .normal)
        }
        if PlayerManager.shared.miniPlayerIsHidden{
            
            
        }else{
            
        }
    }
    
    @objc func handleAudioInterruptions(_ notification:Notification){}
    
    
    @objc func loadFiles() {}
    @objc func removeFiles() {}
    
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if(navigationController!.viewControllers.count > 1){
            return true
        }
        return false
    }
    
    @IBAction func didPressReload(_ sender: UIBarButtonItem) {
        self.loadFiles()
    }
    
    
    @objc func didPressPlay1(_ sender: UIButton) -> MPRemoteCommandHandlerStatus{
        
        self.setPlayImage()
        return .success
    }
    
    
    @objc func forwardPressed(_ sender: UIButton)-> MPRemoteCommandHandlerStatus {
        
        return .success
    }
    
    @objc func rewindPressed(_ sender: UIButton)-> MPRemoteCommandHandlerStatus {
        
        return .success
    }
    
    
    @IBAction func didPressPlay(_ sender: UIButton){
        PlayerManager.shared.playPause()
    }
    
    @IBAction func miniplayerCrossBtn_Action(_ sender: UIButton){
        PlayerManager.shared.miniPlayerIsHidden = true
        self.footerView.isHidden = true
    }
    
    @IBAction func didPressShowDetail(_ sender: UIButton) {
        if d == true{
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let playerVC = storyboard.instantiateViewController(withIdentifier: "PlayerViewController2") as! PlayerViewController
            guard let b = self.cuBook else {return}
            playerVC.book = b
            playerVC.tapDelgate = self
            tabBarController?.selectedIndex = 1
            
        }else{
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let playerVC = storyboard.instantiateViewController(withIdentifier: "PlayerViewController") as! PlayerViewController
            guard let b = self.cuBook else {return}
            playerVC.book = b
            tabBarController?.selectedIndex = 1
          
        }
        
        
    }
    
    @IBAction func uploadFileBtn(_ sender: Any) {
   //     self.addAction()
        self.creatFolder()
    }
    
    func addAction() {
        let alertController = UIAlertController(
            title: nil,
            message: "You can also add files via AirDrop. Send an audiobook file to your device and select SpeedListner from the list that appears.",
            preferredStyle: .actionSheet
        )
        
        alertController.addAction(UIAlertAction(title: "Import files", style: .default) { (_) in
            self.presentImportFilesAlert()
        })
        
        alertController.addAction(UIAlertAction(title: "Create Folder", style: .default) { (_) in
            self.creatFolder()
        })

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc func updatePercentage(_ notification:Notification) {}
    
    
    @objc func bookEnd(_ notification:Notification) {
        self.setPlayImage()
    }
    @objc func updatedFiles(_ notification:Notification) {
        self.loadFiles()
    }
    
    @IBAction func btnCross_Action(_ sender: UIButton) {
        self.searchTxt.text = ""
        self.filterTextfieldData(newString: "")
    }
    
    @IBAction func btnBookShowCover_Action(_ sender: UIButton) {
        
        if checked {
            btnBookshowStatus.setImage( UIImage(named:"ic_outline-check-box-1"), for: .normal)
            UserDefaults.standard.set(false, forKey: "checked")
            checked = false
            
        } else {
            btnBookshowStatus.setImage(UIImage(named:"ic_outline-check-box"), for: .normal)
            checked = true
            UserDefaults.standard.set(true, forKey: "checked")
            
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
        
    }
    @IBAction func toggleSelectionMode(_ sender: UIButton) {
           isSelectionModeEnabled.toggle()
           tableView.reloadData()
       }
    
    @IBAction func btnSortBy_Action(_ sender: UIButton) {
        print("hello i am listening")
        
        UIView.animate(withDuration: 0.3){
            self.tblDrop.isHidden = false
        }
        
    }
    
    @IBAction func btnDot_Action(_ sender: UIButton){
        
        self.topMenu.anchorView = sender
        self.topMenu.bottomOffset = CGPoint(x: -90, y: sender.bounds.height + 8)
        self.topMenu.textColor = .black
        self.topMenu.cornerRadius = 5.0
        self.topMenu.separatorColor = .clear
        self.topMenu.selectionBackgroundColor = .clear
        self.topMenu.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        self.topMenu.dataSource.removeAll()
        self.topMenu.dataSource.append(contentsOf: [
            "Bookmarks",
            "History",
            "SpeedTrack",
            "Settings",
            "Help",
            "Feedback",
            "About"
        ])
        let imagesArr = [
            "bi_bookmark-fill",
            "history",
            "speedtrack",
            "Settings",
            "question",
            "fluent_person-1x",
            "ep_info-filled 1" // 🔁 add your About icon asset name
        ]
       
        topMenu.cellNib = UINib(nibName: "DropDownCell", bundle: nil)
        topMenu.customCellConfiguration = { index, title, cell in
            
            guard let cell = cell as? MyCell1 else {
                return
            }
            cell.img1.image = UIImage(named: imagesArr[index])
            
        }
        self.topMenu.selectionAction = { [unowned self] (index, item) in
            
            switch index {
                
            case 0:
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "BookMarkVC") as! BookMarkVC
                vc.dataBack = { t in
                    PlayerManager.shared.jumpTo(t)
                }
                self.navigationController?.pushViewController(vc, animated: true)
                
            case 1:
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "HistoryViewController") as! HistoryViewController
                self.navigationController?.pushViewController(vc, animated: true)
                
            case 2:
            
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "SpeedTrackViewController") as! SpeedTrackViewController
                self.navigationController?.pushViewController(vc, animated: true)

            case 3:
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "SettingVC") as! SettingVC
                self.navigationController?.pushViewController(vc, animated: true)

            case 4:
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "FAQVC") as! FAQVC
                self.navigationController?.pushViewController(vc, animated: true)

            case 5:
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "FeedbackVC") as! FeedbackVC
                self.navigationController?.pushViewController(vc, animated: true)

            case 6:
                let aboutVC = AboutViewController()
                aboutVC.modalPresentationStyle = .formSheet
                self.present(aboutVC, animated: true)
                
            default:
                break
            }
        }
        self.topMenu.show()
        
    }
    
    
    @IBAction func sortDot_Action(_ sender: UIButton) {
        
        sortMenu.dataSource = ["Newest Upload","Oldest Upload","Recently Played","Alphabetical"]
        sortMenu.anchorView = sender
        sortMenu.bottomOffset = CGPoint(x: 0, y: 50)
        sortMenu.show()
        
        sortMenu.selectionAction = { [weak self] (index: Int, item: String) in
            guard let self = self else { return }

            UserDetail.shared.savedSortBy("\(index)")
            let playlists = self.t_items.compactMap { $0 as? Playlist }
            let books = self.t_items.compactMap { $0 as? Book }

          
            let sortedPlaylists = playlists.sorted {
                ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
            }

            var sortedBooks: [Book] = []

            switch index {
            case 0:
                sortedBooks = books.sorted {
                    ($0.uploadTime ?? Date.distantFuture) > ($1.uploadTime ?? Date.distantPast)
                }
                self.sortByTxt.text = "Newest Upload"
            case 1:
                sortedBooks = books.sorted {
                    ($0.uploadTime ?? Date.distantFuture) < ($1.uploadTime ?? Date.distantPast)
                }
                self.sortByTxt.text = "Oldest Upload"
            case 2:
                sortedBooks = books.sorted {
                    ($0.recentPlayTime ?? Date.distantFuture) > ($1.recentPlayTime ?? Date.distantPast)
                }
                self.sortByTxt.text = "Recently Played"
            case 3:
                sortedBooks = books.sorted {
                    ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
                }
                self.sortByTxt.text = "Alphabetical"
            default:
                sortedBooks = books
            }

         
            self.items = sortedPlaylists + sortedBooks
            self.t_items = self.items

            DispatchQueue.main.async {
                self.tableView.setContentOffset(.zero, animated: true)
                self.tableView.reloadData()
            }
        }
    }
    
    @IBAction func collLeftScroll_Action(_ sender: UIButton){
        
        let collectionBounds = self.collecV.bounds
        let contentOffset = CGFloat(floor(self.collecV.contentOffset.x - collectionBounds.size.width))
        self.moveCollectionToFrame(contentOffset: contentOffset)
    }
    
    func moveCollectionToFrame(contentOffset : CGFloat) {
        
        let frame: CGRect = CGRect(x : contentOffset ,y : self.collecV.contentOffset.y ,width : self.collecV.frame.width,height : self.collecV.frame.height)
        self.collecV.scrollRectToVisible(frame, animated: true)
    }
    
    @IBAction func collRightScroll_Action(_ sender: UIButton){
        let collectionBounds = self.collecV.bounds
        let contentOffset = CGFloat(floor(self.collecV.contentOffset.x + collectionBounds.size.width))
        self.moveCollectionToFrame(contentOffset: contentOffset)
        
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
    
    private func creatFolder(){
        
        let alert = UIAlertController(title: "New folder", message: "Enter Name Of New Folder", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Folder Name"
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { _ in
            if let title = alert.textFields?.first?.text, !title.isEmpty {
                
           
                NewDataMannagerClass.insertPlaylists(title:title, into: nil, or: self.library, completion: { [weak self] _ in
                    guard let self = self else{return}
                    self.loadLibrary()
                })
                
            }
        }
        
        alert.addAction(createAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    private func creatFolderAndInsertBooks(item:LibraryItem){
        
        let alert = UIAlertController(title: "New Folder", message: "Enter Name Of New Folder", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Folder Name"
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { _ in
            if let title = alert.textFields?.first?.text, !title.isEmpty {
                
           
                NewDataMannagerClass.insertPlaylists(title:title, into: nil, or: self.library, completion: { [weak self] playlist in
                    guard let self = self else{return}
                    
                        if item is Book{
                            NewDataMannagerClass.moveBook(item as! Book, from: nil, or: self.library, to: playlist, completion: {
                                self.loadLibrary()
                                
                            })
                        }else{
                            NewDataMannagerClass.movePlaylist(item as! Playlist, or: self.library, from: nil, to: playlist) {
                                self.loadLibrary()
                            }
                        }
                })
                
            }
        }
        
        alert.addAction(createAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    private func presentImportFilesAlert() {
        
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        present(documentPicker, animated: true, completion: nil)
        
    }
}

extension ListBooksViewController {
    
    private func handleAppearanceMode() {
        if traitCollection.userInterfaceStyle == .dark {
            darkModeEnabled()
            print("Dark Mode is active")
        } else {
            lightModeEnabled()
            print("Light Mode is active")
        }
        
    }
    
    private func setupUserCheckedStatus() {
        
        let checked = UserDefaults.standard.object(forKey: "checked") as? Bool ?? false
        
        if checked {
            btnBookshowStatus.setImage(UIImage(named:"ic_outline-check-box"), for: .normal)
            self.checked = true
        } else {
            btnBookshowStatus.setImage(UIImage(named:"ic_outline-check-box-1"), for: .normal)
            self.checked = false
        }
    }
    
    private func setupSearchFieldDelegate() {
        self.tableView.register(UINib(nibName: "BookDetailCell", bundle: nil), forCellReuseIdentifier: "BookDetailCell")
      //  UserDefaults.standard.set(true, forKey: "autoTranscribeWhileListening")
        searchTxt.delegate = self
        searchTxt.autocorrectionType = .no
        searchTxt.autocapitalizationType = .none
        searchTxt.spellCheckingType = .no
        searchTxt.smartDashesType = .no
        searchTxt.smartQuotesType = .no
        searchTxt.smartInsertDeleteType = .no
        searchTxt.reloadInputViews()
    }

    
    @objc private func clearSearchText() {
        searchTxt.text = ""
        filterTextfieldData(newString: "")
    }
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        DispatchQueue.main.async {
            textField.resignFirstResponder() 
        }
        return true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
           textField.resignFirstResponder()
           return true
       }
    
    private func setupPullToRefresh() {
        crossBtnSearch.layer.cornerRadius = 20
        searchTblV.delegate = self
        searchTblV.dataSource = self
        searchTblV.layer.cornerRadius = 10
        searchTblV.layer.masksToBounds = false
        searchTblV.layer.shadowColor = UIColor.black.cgColor
        searchTblV.layer.shadowOpacity = 0.1
        searchTblV.layer.shadowOffset = CGSize(width: 0, height: 4)
        searchTblV.layer.shadowRadius = 8
        searchTblV.backgroundColor = .systemBackground
        searchTblV.separatorInset = .zero
        
        searchTblV.register(SearchResultTableViewCell.self, forCellReuseIdentifier: "SearchResultCell")
        refreshControl.attributedTitle = NSAttributedString(string: "Pull down to reload books")
        refreshControl.addTarget(self, action: #selector(loadLibrary), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    private func setupFooterView() {
        
        tblDrop.isHidden = true
       
        footerView.clipsToBounds = true
        footerView.layer.cornerRadius = 20
        footerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(didPressShowDetail(_:)))
        footerView.addGestureRecognizer(tapRecognizer)
        footerView.isUserInteractionEnabled = true
    }
    
    private func setupRemoteControlListeners() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.skipForwardCommand.isEnabled = true
        commandCenter.skipForwardCommand.preferredIntervals = [10]
        commandCenter.skipForwardCommand.addTarget(self, action: #selector(forwardPressed(_:)))
        
        commandCenter.skipBackwardCommand.isEnabled = true
        commandCenter.skipBackwardCommand.preferredIntervals = [10]
        commandCenter.skipBackwardCommand.addTarget(self, action: #selector(rewindPressed(_:)))
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget(self, action: #selector(didPressPlay1(_:)))
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget(self, action: #selector(didPressPlay1(_:)))
      
    }
    
    private func registerNotifications() {
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(bookChange(_:)), name: Notification.Name.AudiobookPlayer.bookChange, object: nil)
         notificationCenter.addObserver(self, selector: #selector(handleAudioInterruptions(_:)), name: AVAudioSession.interruptionNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(openURL(_:)), name: Notification.Name.AudiobookPlayer.libraryOpenURL, object: nil)
        notificationCenter.addObserver(self, selector: #selector(updatedFiles(_:)), name: Notification.Name.AudiobookPlayer.updateListOfFiles, object: nil)
        notificationCenter.addObserver(self, selector: #selector(bookEnd(_:)), name: Notification.Name.AudiobookPlayer.bookEnd, object: nil)
        notificationCenter.addObserver(self, selector: #selector(bookReady(_:)), name: Notification.Name.AudiobookPlayer.bookReady, object: nil)
        notificationCenter.addObserver(self, selector: #selector(onBookPlay), name: Notification.Name.AudiobookPlayer.bookPlayed, object: nil)
        notificationCenter.addObserver(self, selector: #selector(onBookPause), name: Notification.Name.AudiobookPlayer.bookPaused, object: nil)
        notificationCenter.addObserver(self, selector: #selector(onBookPause), name: Notification.Name.AudiobookPlayer.bookEnd, object: nil)
        notificationCenter.addObserver(self, selector: #selector(onBookStop(_:)), name: Notification.Name.AudiobookPlayer.bookStopped, object: nil)
        notificationCenter.addObserver(self, selector: #selector(updateProgress(_:)), name: Notification.Name.AudiobookPlayer.updatePercentage, object: nil)
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
    }
    
    private func handleUserDetails() {
        let id = UserDetail.shared.getPreviousUserId()
        let currentId = UserDetail.shared.getUserId()
        
        if id != currentId {
            removeFiles()
        }
        
        UserDetail.shared.setPreviousUserId(currentId)
        loadLibrary()
    }
    
    private func loadPreviousBook() {

        guard let identifier = UserDefaults.standard.string(forKey: UserDefaultsConstants.lastPlayedBook),
              let item = PlayerManager.shared.getbookInLibrary(with: identifier) else {
            return
        }

        currentItem = item

        // 🔥 STEP 1: Find correct source (playlist OR library)
        let books: [Book]

        if let playlist = findPlaylistContaining(book: item) {
            PlayerManager.shared.currentPlayList = playlist
            books = (playlist.books?.array as? [Book]) ?? []
        } else {
            PlayerManager.shared.currentPlayList = nil
            // fallback → full library
            books = getAllBooks(from: NewDataMannagerClass.getLibrary())
        }

        // 🔥 STEP 2: Set queue
        let finalQueue = sortBooksAsPerUserPreference(books)
        PlayerManager.shared.playbackQueue = finalQueue
        PlayerManager.shared.currentIndex = finalQueue.firstIndex(of: item) ?? 0

        // 🔥 STEP 3: Load correct book
        PlayerManager.shared.load([item]) { loaded in
            guard loaded else { return }

            NotificationCenter.default.post(
                name: Notification.Name.AudiobookPlayer.playerDismissed,
                object: nil
            )
        }
    }
    func findPlaylistContaining(book: Book) -> Playlist? {

        let library = NewDataMannagerClass.getLibrary()

        guard let items = library.items?.array as? [LibraryItem] else {
            return nil
        }

        for item in items {

            if let playlist = item as? Playlist {

                if let books = playlist.books?.array as? [Book],
                   books.contains(book) {
                    return playlist
                }

                // check nested playlists
                if let found = findInChildPlaylists(book: book, playlist: playlist) {
                    return found
                }
            }
        }

        return nil
    }

    func findInChildPlaylists(book: Book, playlist: Playlist) -> Playlist? {

        if let children = playlist.children?.allObjects as? [Playlist] {
            for child in children {

                if let books = child.books?.array as? [Book],
                   books.contains(book) {
                    return child
                }

                if let found = findInChildPlaylists(book: book, playlist: child) {
                    return found
                }
            }
        }

        return nil
    }
}


extension ListBooksViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == searchTblV {
            return filteredBooks.count + matchedPlaylists.count
        }else{
          return self.items.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == searchTblV {

            let cell = tableView.dequeueReusableCell(withIdentifier: "SearchResultCell", for: indexPath) as! SearchResultTableViewCell

            if indexPath.row < filteredBooks.count {
                let book = filteredBooks[indexPath.row]
                cell.configure(title: book.title ?? "Untitled Book", icon: book.artwork)
            } else {
                let playlist = matchedPlaylists[indexPath.row - filteredBooks.count]
                cell.configure(title: playlist.title ?? "Folder", icon: UIImage(named: "folder"))
            }

            return cell
        }else{
            let item = items[indexPath.row]
            let isSelected = selectedIndices.contains(indexPath)
            let buttonImg = isSelected ? "ic_outline-check-boxdarkmode 1" : "ic_outline-check-boxdarkmode"
            
            if checked {
                let cell = tableView.dequeueReusableCell(withIdentifier: "BookDetailCell", for: indexPath) as! BookDetailCell
                cell.type = item is Playlist ? .playlist : .book
                cell.playbackState = .stopped
                cell.lbl_BookName.text = item.title
                cell.img.image = item.artwork
                
                cell.btnPlay.tag = indexPath.row
                cell.btnPlay.addTarget(self, action: #selector(playBtnTap(_:)), for: .touchUpInside)
                
                if let book = item as? Book {
                    cell.lbl_AutherName.isHidden = false
                    cell.lbl_AutherName.text = book.author
                    cell.lbl_comlition.text = "\(Int(round(item.percentCompleted)))%"
                    cell.lbl_comlition.isHidden = false
                    cell.lbl_subFolderCount.isHidden = true
                    cell.btnPlay.isHidden = false
                } else if let playlist = item as? Playlist {
                    let (bookCount, subfolderCount) = playlist.info()
                    
                    switch (bookCount, subfolderCount) {
                    case ("0", "0"):
                        cell.lbl_AutherName.isHidden = true
                        cell.lbl_subFolderCount.isHidden = true
                    case ("0", _):
                        cell.lbl_AutherName.isHidden = false
                        cell.lbl_AutherName.text = "\(subfolderCount) Subfolder"
                        cell.lbl_subFolderCount.isHidden = true
                    case (_, "0"):
                        cell.lbl_AutherName.isHidden = true
                        cell.lbl_subFolderCount.isHidden = false
                        cell.lbl_subFolderCount.text = "\(bookCount) Books"
                    default:
                        cell.lbl_AutherName.isHidden = false
                        cell.lbl_AutherName.text = "\(subfolderCount) Subfolder"
                        cell.lbl_subFolderCount.isHidden = false
                        cell.lbl_subFolderCount.text = "\(bookCount) Books"
                    }
                    
                    cell.folderIcon_img.isHidden = true
                    cell.lbl_comlition.text = "\(Int(round(playlist.totalProgress() * 100)))%"
                    cell.lbl_comlition.isHidden = true
                    cell.btnPlay.isHidden = true
                }
                
                cell.btnSelect.isHidden = !isSelectionModeEnabled
                cell.selectBtnBgView.isHidden = !isSelectionModeEnabled
                cell.btnSelect.setImage(UIImage(named: buttonImg), for: .normal)
                cell.onSelectButtonTapped = { [weak self] in self?.toggleSelection(at: indexPath) }
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MyBookCell", for: indexPath) as! MyBookCell
                cell.lblBookName.text = item.title
                
                if let book = item as? Book {
                    cell.lblBookAuthor.text = "\(Int(round(book.percentCompleted)))%"
                    cell.folderIcon.isHidden = true
                    cell.lblBookAuthor.isHidden = false
                } else if let playlist = item as? Playlist {
                    cell.lblBookAuthor.text = "\(Int(round(playlist.totalProgress() * 100)))%"
                    cell.lblBookAuthor.isHidden = true
                    cell.folderIcon.isHidden = false
                }
                
                cell.btnSelect.isHidden = !isSelectionModeEnabled
                cell.selectBtnBgView.isHidden = !isSelectionModeEnabled
                cell.btnSelect.setImage(UIImage(named: buttonImg), for: .normal)
                cell.onSelectButtonTapped = { [weak self] in self?.toggleSelection(at: indexPath) }
                cell.selectionStyle = .none
                
                return cell
            }
        }
    }
    
    func toggleSelection(at indexPath: IndexPath) {
        if selectedIndices.contains(indexPath) {
            selectedIndices.remove(indexPath)
        } else {
            selectedIndices.insert(indexPath)
           
        }
   
            toggleBottomSheet()
      
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
    private func setupBottomSheet() {
           let bottomSheet = BottomSheetViewController()
           bottomSheetVC = bottomSheet
        bottomSheet.onActionSelected = { [weak self] action in
               self?.handleBottomSheetAction(action)
           }
        
           addChild(bottomSheet)
           
           bottomSheet.view.translatesAutoresizingMaskIntoConstraints = false
           view.addSubview(bottomSheet.view)
           bottomSheet.didMove(toParent: self)
           
           // Initial Position: Off-screen
           NSLayoutConstraint.activate([
               bottomSheet.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
               bottomSheet.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
               bottomSheet.view.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.21),
               bottomSheet.view.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 300)
           ])
        tabBarController?.selectedIndex = 1
       }
       
       @objc private func toggleBottomSheet() {
           if
            self.selectedIndices.isEmpty{
               self.isBottomSheetVisible = true
           }else{
              
               self.isBottomSheetVisible = false
           }
           
           guard let bottomSheet = bottomSheetVC else { return }
           let isVisible = isBottomSheetVisible
           
           UIView.animate(withDuration: 0.3, animations: {
               bottomSheet.view.frame.origin.y = isVisible
                   ? self.view.frame.height // Hide it
                   : self.view.frame.height - bottomSheet.view.frame.height // Show it
           }) { _ in
             
           }
       
   }
    private func handleBottomSheetAction(_ action: BottomSheetViewController.ActionType) {
        let selectedItems = selectedIndices.compactMap { $0.row < items.count ? items[$0.row] : nil }
        
        switch action {
        case .delete:
            selectedItems.forEach { item in
                if let book = item as? Book {
                    handleDelete(book: book, alert: false)
                    clearAllSelections()
                } else if let playlist = item as? Playlist {
                    handleDelete(playlist: playlist, alert: false)
                    clearAllSelections()
                }
            }
            
        case .move:
            let sheet = UIAlertController(title: "\(selectedItems.count) items", message: nil, preferredStyle: .alert)
            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            sheet.addAction(UIAlertAction(title: "Existing Folder", style: .default) { _ in
                
//                func presentPlaylistTableView(item:LibraryItem) {
                    let playlistTableVC = PlaylistTableViewController()
                playlistTableVC.playlists = self.items.compactMap {
                                   if let playlist = $0 as? Playlist, !selectedItems.contains(playlist) {
                                       return playlist
                                   }
                                   return nil
                               }
                    playlistTableVC.items = selectedItems
                    playlistTableVC.delegate = self
                    playlistTableVC.allowMoveToParent = false
                    playlistTableVC.allowMoveToRoot = false
                    let navController = UINavigationController(rootViewController: playlistTableVC)
                self.clearAllSelections()
                self.present(navController, animated: true, completion: nil)
//                }
//                let playlistTableVC = PlaylistTableViewController()
//                playlistTableVC.playlists = self.items.compactMap {
//                    if let playlist = $0 as? Playlist, !selectedItems.contains(playlist) {
//                        return playlist
//                    }
//                    return nil
//                }
//               playlistTableVC.items = selectedItems
//                
//                playlistTableVC.delegate = self
//                let navController = UINavigationController(rootViewController: playlistTableVC)
//                self.present(navController, animated: true, completion: nil)
            })

            sheet.addAction(UIAlertAction(title: "New Folder", style: .default) { _ in
                self.createNewPlaylist(with: selectedItems)
            })

            self.present(sheet, animated: true)
           
            
        case .cancel:
            resetSelection()
        }
    }

    private func resetSelection() {
        selectedIndices.removeAll()
        isSelectionModeEnabled.toggle()
        toggleBottomSheet()
        tableView.reloadData()
    }

    private func createNewPlaylist(with selectedItems: [LibraryItem]) {
        let alert = UIAlertController(title: "New Folder", message: "Enter Name Of New Folder", preferredStyle: .alert)
        alert.addTextField { $0.placeholder = "Folder Name" }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Create", style: .default) { _ in
            if let title = alert.textFields?.first?.text, !title.isEmpty {
                NewDataMannagerClass.insertPlaylists(title: title, into: nil, or: self.library) { [weak self] playlist in
                    guard let self = self else { return }
                    selectedItems.forEach { item in
                        if let book = item as? Book {
                            NewDataMannagerClass.moveBook(book, from: nil, or: self.library, to: playlist, completion: self.loadLibrary)
                        } else if let playlistItem = item as? Playlist {
                            NewDataMannagerClass.movePlaylist(playlistItem, or: self.library, from: nil, to: playlist, completion: self.loadLibrary)
                        }
                    }
                    resetSelection()
                }
            }
        })
        
        self.present(alert, animated: true)
    }
    
    
    @objc func playBtnTap(_ sender:UIButton){
        PlayerManager.shared.miniPlayerIsHidden = false
        
        let item = self.items[sender.tag]
        currentItem = self.items[sender.tag]
        if let book = item as? Book {
            print(book.currentTime,book.duration,"duratin matching")
            if Int( book.currentTime) == Int(book.duration) {
                book.currentTime = 0.0
                NewDataMannagerClass.saveContext()
            }
            self.setupPlayer(books: [book])
            
        } else if let playlist = item as? Playlist {
            
            PlayerManager.shared.currentPlayList = playlist
            PlayerManager.shared.currentPlayListIndex = sender.tag
          
            self.setupPlayer(books: playlist.getRemainingBooks())
            
        }
        
    }
    
    
     func searchResultBookPlay(_ book:Book?){
        PlayerManager.shared.miniPlayerIsHidden = false
        
      
        if let book = book {
            print(book.currentTime,book.duration,"duratin matching")
            if Int( book.currentTime) == Int(book.duration) {
                book.currentTime = 0.0
                NewDataMannagerClass.saveContext()
            }
            self.setupPlayer(books: [book])
            
        }
        
    }
    func showPlayerView(book:Book) {
       
        if d {
            if let playerVC = self.storyboard!.instantiateViewController(withIdentifier: "PlayerViewController2") as? PlayerViewController {
                playerVC.book = book
                playerVC.tapDelgate = self
                PlayerManager.shared.playPause()
                self.tabBarController?.selectedIndex = 1
                
            }
        }else{
            if let playerVC = self.storyboard!.instantiateViewController(withIdentifier: "PlayerViewController") as? PlayerViewController {
                playerVC.book = book
                playerVC.tapDelgate = self
                PlayerManager.shared.playPause()
                self.tabBarController?.selectedIndex = 1
            
            }
        }
      
    }
    
    func setupPlayer(books: [Book]) {
     
        guard let book = books.first else {
            
            return
            
        }
        if Int( book.currentTime) == Int(book.duration) {
            book.currentTime = 0.0
            NewDataMannagerClass.saveContext()
        }
        guard let currentBook = PlayerManager.shared.currentBook, currentBook.fileURL == book.fileURL else {
          
            self.loadPlayer(books: books)
         
            return
        }
        
        self.showPlayerView(book: book)
    }
    
    
    func loadPlayer(books: [Book]) {

        guard let book = books.first else { return }

        guard NewDataMannagerClass.exists(book) else {
            self.showAlert(
                "File Missing!",
                message: "This Audiobook File Was Removed From Your Device.",
                style: .alert
            )
            return
        }

        var finalQueue: [Book] = books

        if books.count == 1 {

               if let playlist = findPlaylistContaining(book: book) {
                   let playlistBooks = (playlist.books?.array as? [Book]) ?? []
                   finalQueue = sortBooksAsPerUserPreference(playlistBooks)
               }
               else {
                   let libraryBooks = getAllBooks(from: NewDataMannagerClass.getLibrary())
                   finalQueue = sortBooksAsPerUserPreference(libraryBooks)
               }

           } else {
               //if multiple books come from UI
               finalQueue = sortBooksAsPerUserPreference(books)
           }




        // STEP 1: SET QUEUE
        PlayerManager.shared.playbackQueue = finalQueue

        // STEP 2: SET INDEX
        PlayerManager.shared.currentIndex = finalQueue.firstIndex(of: book) ?? 0

        // STEP 3: LOAD CURRENT BOOK ONLY
        finalQueue.forEach { item in
            print("finalQueue items >" ,item.title ?? "")
        }
     
        PlayerManager.shared.load([book]) { loaded in

            guard loaded else {
                self.showAlert(
                    "File error!",
                    message: "This Audiobook file couldn't be loaded.",
                    style: .alert
                )
                return
            }

            self.ensureCategoryAssigned(for: book) {
                self.showPlayerView(book: book)
                PlayerManager.shared.play()
            }
        }
    }
    
    func getLibraryBooksInOrder() -> [Book] {

        let library = NewDataMannagerClass.getLibrary()

        guard let items = library.items?.array as? [LibraryItem] else {
            return []
        }

        var books: [Book] = []

        for item in items {
            if let book = item as? Book {
                books.append(book)
            }
        }

        return books
    }
    
    
    func sortBooksAsPerUserPreference(_ books: [Book]) -> [Book] {

        switch UserDetail.shared.getSortBy() {

        case "0": // Newest Upload
            return books.sorted {
                ($0.uploadTime ?? Date.distantPast) >
                ($1.uploadTime ?? Date.distantPast)
            }

        case "1": // Oldest Upload
            return books.sorted {
                ($0.uploadTime ?? Date.distantPast) <
                ($1.uploadTime ?? Date.distantPast)
            }

        case "2": // Recently Played
            return books.sorted {
                ($0.recentPlayTime ?? Date.distantPast) >
                ($1.recentPlayTime ?? Date.distantPast)
            }

        case "3": // Alphabetical
            return books.sorted {
                ($0.title ?? "")
                    .localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
            }

        default:
            return books
        }
    }
    
//    commented on 18 march 26
//    func loadPlayer(books: [Book]) {
//        guard let book = books.first else { return }
//        
//        guard NewDataMannagerClass.exists(book) else {
//            self.showAlert(
//                "File Missing!",
//                message: "This Audiobook File Was Removed From Your Device. Import The File Again To Play The Audiobook.",
//                style: .alert
//            )
//            return
//        }
//        
//        PlayerManager.shared.load(books) { (loaded) in
//            guard loaded else {
//                self.showAlert(
//                    "File Missing!",
//                    message: "This Audiobook File Was Removed From Your Device. Import The File Again To Play The Audiobook.",
//                    style: .alert
//                )
//                return
//            }
//            PlayerManager.shared.playPause()
//            self.tabBarController?.selectedIndex = 1
//           
//        }
//    }
    
    @objc func bookReady() {
        self.tableView.reloadData()
    }
    
}

extension ListBooksViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canFocusRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 0 else { return nil }
        
        let item = self.items[indexPath.row]
        
        let options =  UIContextualAction(style: .normal, title: "Options") { [weak self] _, _, done in
            guard let self else { return }
            self.showBottomOptions(for: item, indexPath: indexPath)
            done(true)
        }
        
        options.backgroundColor = .gray
        
        let config = UISwipeActionsConfiguration(actions: [options])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    
    func handleDelete(book: Book, indexPath: IndexPath? = nil,alert:Bool? = true) {
        if alert ?? false{
            let alert = UIAlertController(title: "All The Notes Associated With This Audiobook Will Be Deleted!", message: "Do You Really Want To Delete: \(book.title ?? "")...?", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                self.tableView.setEditing(false, animated: true)
            }))
            
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                if book == PlayerManager.shared.currentBook {
                    PlayerManager.shared.stop()
                }
                
                NewDataMannagerClass.delete(book: book, from: self.library, or: nil, deleteFile: true)
          
                self.loadLibrary()
                
            }))
            
            alert.popoverPresentationController?.sourceView = self.view
            alert.popoverPresentationController?.sourceRect = CGRect(x: Double(self.view.bounds.size.width / 2.0), y: Double(self.view.bounds.size.height - 45), width: 1.0, height: 1.0)
            
            self.present(alert, animated: true, completion: nil)
        }else{
            if book == PlayerManager.shared.currentBook {
                PlayerManager.shared.stop()
            }
            
            NewDataMannagerClass.delete(book: book, from: self.library, or: nil, deleteFile: true)
            self.loadLibrary()
        }
      
    }
    
    func handleDelete(playlist: Playlist, indexPath: IndexPath? = nil, alert: Bool? = true) {

     
        if playlistOrDescendantsContainBooks(playlist) {
            let sheet = UIAlertController(
                title: "Cannot Delete Folder",
                message: """
                This Folder Contains Audiobooks (Possibly Inside Sub-Folders).
                Please Delete Or Move All Audiobooks First Before Deleting This Folder.
                """,
                preferredStyle: .alert
            )

            sheet.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(sheet, animated: true)
            return
        }

        if alert ?? true {
            let sheet = UIAlertController(
                title: "Delete Folder",
                message: "Are you sure you want to delete \"\(playlist.title ?? "")\"?",
                preferredStyle: .alert
            )

            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

            sheet.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                NewDataMannagerClass.delete(playlist: playlist, from: self.library, or: nil, deleteBooks: false)
                self.loadLibrary()
            }))

            self.present(sheet, animated: true)
        } else {
            NewDataMannagerClass.delete(playlist: playlist, from: self.library, or: nil, deleteBooks: false)
            self.loadLibrary()
        }
    }
    
    private func moveLibraryItem(item: LibraryItem, indexPath: IndexPath? = nil){
        let sheet = UIAlertController(title: "\(item.title ?? "Unknown")", message: nil, preferredStyle: .alert)
        
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        sheet.addAction(UIAlertAction(title: "Existing Folder", style: .default, handler: { _  in
            self.presentPlaylistTableView(item: item)
            
        }))
        
        sheet.addAction(UIAlertAction(title: "New Folder", style: .default, handler: { _ in
            self.creatFolderAndInsertBooks(item: item)
            
        }))
        self.present(sheet, animated: true, completion: nil)

        
    }
   
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if checked {
            return UITableView.automaticDimension
        }else{
            return 50
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        guard let index = tableView.indexPathForSelectedRow else {
            return indexPath
        }
        
        tableView.deselectRow(at: index, animated: true)
        
        return indexPath
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == searchTblV {

            if indexPath.row < filteredBooks.count {
                self.searchResultBookPlay(self.filteredBooks[indexPath.row])
            } else {
                let playlist = matchedPlaylists[indexPath.row - filteredBooks.count]

                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let playlistVC = storyboard.instantiateViewController(withIdentifier: "NewPlaylistViewController") as? NewPlaylistViewController {
                    playlistVC.playlist = playlist
                    playlistVC.comeFrom = "1"
                    playlistVC.p = "1"
                    self.navigationController?.pushViewController(playlistVC, animated: true)
                }
            }
        }else{
            PlayerManager.shared.miniPlayerIsHidden = false
            let item = self.items[indexPath.row]
            
            guard let book = item as? Book else {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                if let playlist = item as? Playlist, let playlistVC = storyboard.instantiateViewController(withIdentifier: "NewPlaylistViewController") as? NewPlaylistViewController {
                    
                    playlistVC.playlist = playlist
                    playlistVC.comeFrom = "1"
                    playlistVC.p = "1"
                    self.navigationController?.pushViewController(playlistVC, animated: true)
                }
                
                return
            }
            self.setupPlayer(books: [book])
            
        }
    }
    
}


extension ListBooksViewController {
    override func remoteControlReceived(with event: UIEvent?) {
        guard let event = event else {
            return
        }
        // TODO: after decoupling AVAudioPlayer from the PlayerViewController
        switch event.subtype {
        case .remoteControlTogglePlayPause:
            print("toggle play/pause")
        case .remoteControlBeginSeekingBackward:
            print("seeking backward")
        case .remoteControlEndSeekingBackward:
            print("end seeking backward")
        case .remoteControlBeginSeekingForward:
            print("seeking forward")
        case .remoteControlEndSeekingForward:
            print("end seeking forward")
        case .remoteControlPause:
            print("control pause")
        case .remoteControlPlay:
            print("control play")
        case .remoteControlStop:
            print("stop")
        case .remoteControlNextTrack:
            print("next track")
        case .remoteControlPreviousTrack:
            print("previous track")
        default:
            print(event.description)
        }
    }
}


extension ListBooksViewController: PlaylistSelectionDelegate {
    func didSelectPlaylist(_ playlist: Playlist, from items: [LibraryItem]?) {
            guard let items = items else { return }

            let library = NewDataMannagerClass.getLibrary()

            for item in items {
                if let book = item as? Book {
                    library.removeFromItems(book)
                    playlist.addToBooks(book)
                } else if let sub = item as? Playlist {
                    library.removeFromItems(sub)
                    playlist.addToChildren(sub)
                }
            }

            NewDataMannagerClass.saveContext()
            self.loadLibrary()
            NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.reloadData, object: nil)
        

        selectedIndices.removeAll()
        isSelectionModeEnabled = false
        toggleBottomSheet()
        tableView.reloadData()
    }
    
    
    func presentPlaylistTableView(item:LibraryItem) {
        let playlistTableVC = PlaylistTableViewController()
        playlistTableVC.playlists = self.items.compactMap {
            if let playlist = $0 as? Playlist, playlist.title != item.title {
                return playlist
            }
            return nil
        }
        playlistTableVC.item = item
        playlistTableVC.delegate = self
        playlistTableVC.allowMoveToParent = false
        playlistTableVC.allowMoveToRoot = false
        let navController = UINavigationController(rootViewController: playlistTableVC)
        present(navController, animated: true, completion: nil)
    }
    
    func didSelectPlaylist(_ playlist: Playlist, from item: LibraryItem?) {
            if let item = item {
                self.didSelectPlaylist(playlist, from: [item])
            }
        }
    
 
    func playlistOrDescendantsContainBooks(_ playlist: Playlist) -> Bool {

        if let books = playlist.books, books.count > 0 {
            return true
        }

        if let children = playlist.children?.allObjects as? [Playlist] {
            for child in children {
                if playlistOrDescendantsContainBooks(child) {
                    return true
                }
            }
        }

        return false
    }

    
}


extension ListBooksViewController:UICollectionViewDelegate,UICollectionViewDataSource,UITextFieldDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        AlphabetArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collecV.dequeueReusableCell(withReuseIdentifier: "AlphabetsCell", for: indexPath) as! AlphabetsCell
        cell.lblAlpha.text = AlphabetArr[indexPath.row]
        
        if AlphabetArr[indexPath.row] == selectedTxt {
            cell.lblAlpha.font = .systemFont(ofSize: 22)
        }else{
            cell.lblAlpha.font = .systemFont(ofSize: 16)
        }
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if selectedTxt == AlphabetArr[indexPath.row]{
            self.selectedTxt = ""
          // self.filterData(newString:"")
        }else{
            let vc = storyboard?.instantiateViewController(withIdentifier: "LetterSearchVC") as! LetterSearchVC
            
            vc.latterSerch = AlphabetArr[indexPath.row]
            vc.selectedTxt = AlphabetArr[indexPath.row]
            self.selectedTxt = AlphabetArr[indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
         //   self.filterData(newString: self.selectedTxt)
        }
        
        self.collecV.reloadData()
    }
    
    func filterData(newString: String) {
      
        if !newString.isEmpty {
          
            let filteredArray = t_items.filter { item in
                let titleFirstLetter = String(item.title?.prefix(1) ?? "unknown")
                let newStringFirstLetter = String(newString.prefix(1))
                return titleFirstLetter.caseInsensitiveCompare(newStringFirstLetter) == .orderedSame
            }
            items = filteredArray
        } else {
            items = t_items
        }
        
        self.tableView.reloadData()
    }
    
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.addTarget(self, action: #selector(valueChange(_:)), for: .editingChanged)
    }
    
    
    @objc func valueChange(_ textField:UITextField){
       // 24 nov 25 change request
        self.filterTextfieldData(newString: textField.text ?? "")
    }
    
    func filterTextfieldData(newString: String) {

        debounceWorkItem?.cancel()

        let filterWork = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            let cleanedInput = newString
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .lowercased()

            let searchWords = cleanedInput.split(separator: " ")

            // 🔥 MAIN FILTER (Library visible list)
            if !cleanedInput.isEmpty {

                let filteredArray = self.t_items.filter { item in

                    let title = item.title?.lowercased() ?? ""
                    let author = (item as? Book)?.author?.lowercased() ?? ""

                    let titleMatch = searchWords.allSatisfy { word in
                        title.contains(word)
                    }

                    let authorMatch = searchWords.allSatisfy { word in
                        author.contains(word)
                    }

                    return titleMatch || authorMatch
                }

                self.items = filteredArray

            } else {
                let playlists = self.t_items.compactMap { $0 as? Playlist }
                let books = self.t_items.compactMap { $0 as? Book }

                self.items = playlists + books
            }

            // 🔥 अगर input empty है → hide dropdown
            if cleanedInput.isEmpty {
                filteredBooks = []
                matchedPlaylists = []
                self.searchTblV.isHidden = true
                return
            }

            // 🔥 DROPDOWN BOOKS (NOT IN CURRENT LIST)
            filteredBooks = self.getAllBooks(from: self.library).filter { book in

                let title = book.title?.lowercased() ?? ""

                let matchesSearch = searchWords.allSatisfy { word in
                    title.contains(word)
                }

                let alreadyVisible = self.items.contains {
                    if let visibleBook = $0 as? Book {
                        return visibleBook.identifier == book.identifier
                    }
                    return false
                }

                return matchesSearch && !alreadyVisible
            }

            // 🔥 DROPDOWN PLAYLISTS
            matchedPlaylists = self.getAllPlaylists(from: self.library).filter { playlist in

                let title = playlist.title?.lowercased() ?? ""

                let matchesSearch = searchWords.allSatisfy { word in
                    title.contains(word)
                }

                let alreadyVisible = self.items.contains {
                    if let visiblePlaylist = $0 as? Playlist {
                        return visiblePlaylist.identifier == playlist.identifier
                    }
                    return false
                }

                return matchesSearch && !alreadyVisible
            }

            // 🔥 HEIGHT CALCULATION
            let rowHeight: CGFloat = 40
            let maxHeight: CGFloat = 200
            let totalResults = filteredBooks.count + matchedPlaylists.count
            let calculatedHeight = min(CGFloat(totalResults) * rowHeight, maxHeight)

            self.searchTblVH.constant = calculatedHeight

            self.searchTblV.isHidden = totalResults == 0
            self.searchTblV.reloadData()
        }

        debounceWorkItem = filterWork
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4, execute: filterWork)

        // 🔥 AUTO KEYBOARD HIDE (optional)
        keyboardHideWorkItem?.cancel()
        let hideWork = DispatchWorkItem { [weak self] in
            self?.view.endEditing(true)
        }
        keyboardHideWorkItem = hideWork
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: hideWork)
    }
    
    func getAllPlaylists(from library: Library) -> [Playlist] {
        var result: [Playlist] = []
        
        guard let items = library.items else { return [] }

        for item in items {
            if let playlist = item as? Playlist {
                result.append(playlist)
                result.append(contentsOf: getAllPlaylists(from: playlist))
            }
        }

        return result
    }

    func getAllPlaylists(from playlist: Playlist) -> [Playlist] {
        var result: [Playlist] = []

        if let children = playlist.children as? Set<Playlist> {
            for child in children {
                result.append(child)
                result.append(contentsOf: getAllPlaylists(from: child))
            }
        }

        return result
    }
    
    func getAllBooks(from library: Library) -> [Book] {
        var result: [Book] = []

        guard let items = library.items  else { return result }

        for item in items {
            if let book = item as? Book {
                result.append(book)
            } else if let playlist = item as? Playlist {
                result.append(contentsOf: getAllBooks(from: playlist))
            }
        }

        return result
    }

    func getAllBooks(from playlist: Playlist) -> [Book] {
        var result: [Book] = []

        if let books = playlist.books?.array as? [Book] {
            result.append(contentsOf: books)
        }

        if let children = playlist.children as? Set<Playlist> {
            for child in children {
                result.append(contentsOf: getAllBooks(from: child))
            }
        }

        return result
    }
    
    
}

extension ListBooksViewController:TapOnOptions{
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
                PlayerManager.shared.jumpTo(t)
            }
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
   
}

//MARK: -> Mini player listenrs

extension ListBooksViewController {
    
    @objc private func bookReady(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let book = userInfo["book"] as? Book else {
            return
        }
        self.cuBook = book
        currentBok = book
        self.footerView.isHidden = false
        setupMiniPlayer(book: book)
        guard let index = self.items.firstIndex(where: { $0.identifier == book.identifier }) else {
            print("Book not found")
            return
        }
        items[index].recentPlayTime = Date()
        PlayerManager.shared.isRecentCheck = true
       
        
    }
    
    @objc private func bookChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let books = userInfo["books"] as? [Book],
              let currentBook = books.first else {
            return
        }
        currentBok = currentBook
        self.cuBook = currentBook
        setupMiniPlayer(book: currentBook)
        PlayerManager.shared.playPause()
        
    }
    
    func setupMiniPlayer(book:Book){
      
        let title = book.title
        let author = book.author ?? "Unknown"
        self.footerImageView.image = book.artwork
        self.footerTitleLabel.text = (title ?? "unknown") + " - " + author
        self.setPlayImage()
    }
    
    
    @objc private func onBookPlay() {
        self.footerPlayButton.setImage(self.miniPauseButton, for: .normal)
        self.tableView.reloadData()
        guard
            let book = PlayerManager.shared.currentBook,
            let index = self.itemIndex(with: book.fileURL),
            let bookCell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? BookDetailCell
        else {
            return
        }
        
        bookCell.playbackState = .playing
    }
    
    
    func itemIndex(with url: URL) -> Int? {
        let hash = url.lastPathComponent
        return self.itemIndex(with: hash)
    }
    
    func itemIndex(with identifier: String) -> Int? {
        let items = self.items

        for (index, item) in items.enumerated() {
            if let storedBook = item as? Book,
               storedBook.identifier == identifier {
                return index
            }
           
            if let playlist = item as? Playlist {
                print(playlist.title ?? "","Checking nested playlist")

                if let isAvailable = findBookInPlaylist(playlist, with: identifier) {
                    return index
                }
            }
        }

        return nil
    }

    private func findBookInPlaylist(_ playlist: Playlist, with identifier: String) -> Bool? {
        let books = playlist.books?.array as? [Book] ?? []
    
        if let bookIndex = books.firstIndex(where: { $0.identifier == identifier }) {
            return true
        }
        let childPlaylists = playlist.children?.allObjects as? [Playlist] ?? []
        for childPlaylist in childPlaylists {
            if let nestedIndex = findBookInPlaylist(childPlaylist, with: identifier) {
                return true
            }
        }

        return false
    }
    
    
    @objc private func onBookPause() {
        self.footerPlayButton.setImage(self.miniPlayImage, for: .normal)
        guard
            let book = PlayerManager.shared.currentBook,
            let index = self.itemIndex(with: book.fileURL),
            let bookCell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? BookDetailCell
        else {
            
            return
        }
        
        bookCell.playbackState = .paused
    }
    
    @objc func onBookStop(_ notification: Notification) {
        
        guard
            let userInfo = notification.userInfo,
            let book = userInfo["book"] as? Book,
            let index = self.library.itemIndex(with: book.fileURL),let bookCell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? BookDetailCell
        else {
            return
        }
        
        bookCell.playbackState = .stopped
     
    }
    
    @objc func updateProgress(_ notification: Notification) {
        let index = PlayerManager.shared.currentPlayListIndex ?? 0
        if let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? BookDetailCell,cell.type == .playlist {
            if PlayerManager.shared.isRecentCheck {
                items[index].recentPlayTime = Date()
                PlayerManager.shared.isRecentCheck = false
                //
            }else{
                
            }
            
            cell.lbl_comlition.text = "\(Int(((items[index] as? Playlist)?.totalProgress() ?? 0.0) * 100))%"
        }
        guard let userInfo = notification.userInfo,
              let fileURL = userInfo["fileURL"] as? URL,
              let progress = userInfo["progress"] as? Double else {
            return
        }
        
        guard let index = (self.items.firstIndex { (item) -> Bool in
            if let book = item as? Book {
                return book.fileURL == fileURL
            }
            
            return false
        }), let cell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? BookDetailCell else {
            return
        }
        cell.progress = progress
        
    }
}

//MARK: - Dark/Light mode logic
extension ListBooksViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        switch traitCollection.userInterfaceStyle {
        case .dark: darkModeEnabled()   // Switch to dark mode colors, etc.
        case .light: fallthrough
        case .unspecified: fallthrough
        default: lightModeEnabled()   // Switch to light mode colors, etc.
        }
    }
    
    private func lightModeEnabled() {
        searchTxt.attributedPlaceholder = NSAttributedString(string:"Search Your Books", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 40/255, green: 0, blue: 71/255, alpha: 1)])
        //        self.topMenu.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
    }
    private func darkModeEnabled() {
        searchTxt.attributedPlaceholder = NSAttributedString(string:"Search Your Books", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
       
    }
}

extension ListBooksViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        processFilesSequentially(at: urls, index: 0)
    }

    func processFilesSequentially(at urls: [URL], index: Int) {
        guard index < urls.count else {
            NewDataMannagerClass.saveContext()
            self.loadLibrary()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            return
        }
        
        let url = urls[index]
        processNextFile(at: url) { [weak self] in
            self?.processFilesSequentially(at: urls, index: index + 1)
        }
    }

    func processNextFile(at url: URL, completion: @escaping () -> Void) {
        if url.startAccessingSecurityScopedResource() {
            defer { url.stopAccessingSecurityScopedResource() }
            
            let destinationFolder = NewDataMannagerClass.getProcessedFolderURL()
            NewDataMannagerClass.processFile(at: url, destinationFolder: destinationFolder) { [weak self] processedURL in
                guard let self = self else { return }
                guard let processedURL = processedURL else {
                    print("Failed to process file: \(url.lastPathComponent)")
                    completion()
                    return
                }

           
                guard let items = self.library.items?.array as? [LibraryItem] else {
                    completion()
                    return
                }
                let existingBooks = items.compactMap { $0 as? Book }

                let asset = AVAsset(url: processedURL)
                let newDuration = CMTimeGetSeconds(asset.duration)
                let newTitle = processedURL.deletingPathExtension().lastPathComponent

                if let duplicateBook = existingBooks.first(where: { book in
                   
                    let normalizedNewTitle = newTitle
                          .lowercased()
                          .replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression) // remove punctuation
                          .trimmingCharacters(in: .whitespacesAndNewlines)
                      
                      let normalizedExistingTitle = (book.title ?? "")
                          .lowercased()
                          .replacingOccurrences(of: "[^a-z0-9 ]", with: "", options: .regularExpression)
                          .trimmingCharacters(in: .whitespacesAndNewlines)
                      
                      print("Comparing:", normalizedNewTitle, "vs", normalizedExistingTitle)

                      let isSameTitle = normalizedNewTitle.contains(normalizedExistingTitle) ||
                                        normalizedExistingTitle.contains(normalizedNewTitle)
                      
                      let isSameDuration = abs(book.duration - newDuration) < 2
                    
                    print(newTitle,newDuration,book.title?.lowercased(),book.duration,"isSameDuration")
                      return isSameTitle && isSameDuration
                }) {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(
                            title: "Duplicate Audiobook",
                            message: "There is already an audiobook named '\(duplicateBook.title ?? "Unknown")' in your library. Do you still want to upload this audiobook?",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
                            completion()
                        }))
                        alert.addAction(UIAlertAction(title: "Upload Anyway", style: .default, handler: { _ in
                            self.insertBook(url: processedURL, original: url, completion: completion)
                        }))
                        self.present(alert, animated: true)
                    }
                } else {
                    // No duplicate → insert directly
                    self.insertBook(url: processedURL, original: url, completion: completion)
                }
            }
        } else {
            print("Couldn't access the file: \(url.lastPathComponent)")
            completion()
        }
    }

    private func insertBook(url: URL, original: URL, completion: @escaping () -> Void) {
        let bookUrl = BookURL(original: original, processed: url)
        self.queue.addOperation {
            NewDataMannagerClass.insertBooks(from: [bookUrl], into: nil, or: self.library) {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
    
    // MARK: - Multi-select state reset
    func clearAllSelections() {
        
        isSelectionModeEnabled = false
        selectedIndices.removeAll()
        self.selectedTxt.removeAll()
        if isBottomSheetVisible {
            toggleBottomSheet()
        }
        self.tableView.reloadData()
    }
    func showBottomOptions(for item: LibraryItem, indexPath: IndexPath) {
        view.subviews.compactMap { $0 as? BottomOptionsBar }.forEach { $0.removeFromSuperview() }
        
        let bar = BottomOptionsBar()
        
        bar.onMove = { [weak self] in
            guard let self else { return }
            bar.dismiss()
            self.moveLibraryItem(item: item, indexPath: indexPath)
        }
        
        bar.onRename = { [weak self] in
            guard let self else { return }
            bar.dismiss()
            
            if let playlist = item as? Playlist {
                let alert = UIAlertController(title: "Rename Folder", message: nil, preferredStyle: .alert)
                alert.addTextField { tf in
                    tf.text = playlist.title
                }
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "Rename", style: .default) { _ in
                    if let new = alert.textFields?.first?.text, new != playlist.title {
                        playlist.title = new
                        NewDataMannagerClass.saveContext()
                        self.tableView.reloadData()
                    }
                })
                self.present(alert, animated: true)
            }else if let book = item as? Book{
                let alert = UIAlertController(title: "Rename Book", message: nil, preferredStyle: .alert)
                alert.addTextField { tf in
                    tf.text = book.title
                }
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                alert.addAction(UIAlertAction(title: "Rename", style: .default) { _ in
                    if let new = alert.textFields?.first?.text, new != book.title {
                        book.title = new
                        NewDataMannagerClass.saveContext()
                        self.tableView.reloadData()
                    }
                })
                self.present(alert, animated: true)
            }
        }
        
        bar.onDelete = { [weak self] in
            guard let self else { return }
            bar.dismiss()
            
            if let book = item as? Book {
                self.handleDelete(book: book, indexPath: indexPath)
            } else if let playlist = item as? Playlist {
                self.handleDelete(playlist: playlist, indexPath: indexPath)
            }
        }
        
        bar.onCancel = {
            bar.dismiss()
        }
        
        bar.present(in: self.view)
    }
}


class BookCellView: UITableViewCell {
    
    @IBOutlet weak var artworkImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var completionLabel: UILabel!
    
}
