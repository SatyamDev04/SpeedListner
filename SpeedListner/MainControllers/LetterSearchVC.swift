//
//  NewPlaylistViewController.swift
//  SpeedListner
//  Created by YATIN  KALRA on 06/09/24.
//  
//


import UIKit
import DropDown
import AVFoundation

class LetterSearchVC: UIViewController {
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerImageView: UIImageView!
    @IBOutlet weak var footerTitleLabel: UILabel!
    @IBOutlet weak var footerPlayButton: UIButton!
    @IBOutlet weak var playListTitle: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collecV: UICollectionView!
    @IBOutlet weak var btnBookshowStatus: UIButton!
    @IBOutlet weak var searchTxt: UITextField!
    @IBOutlet weak var sortByTxt: UILabel!
    @IBOutlet weak var searchTblV: UITableView!
    @IBOutlet weak var searchTblVH: NSLayoutConstraint!
    
    let topMenu = DropDown()
    let queue = OperationQueue()
    var playlist: Playlist!
    var playlistItems: [LibraryItem] = []
    let library = NewDataMannagerClass.getLibrary()
    var comeFrom = ""
    var p = ""
    var playlistName = [String]()
    let sortMenu = DropDown()
    var t_items = [LibraryItem]()
    var AlphabetArr = (65...90).map { String(UnicodeScalar($0)) }
    var selectedTxt = ""
    var checked = false
    var isSelectionModeEnabled = false
    let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
    var selectedIndices = Set<IndexPath>()
    private var isBottomSheetVisible = false
    private var bottomSheetVC: BottomSheetViewController?
    var debounceWorkItem: DispatchWorkItem?
 
    var filteredBooks: [Book] = []
    var matchedPlaylists: [Playlist] = []
    var isSearching = false
    var latterSerch: String = ""
    private var keyboardHideWorkItem: DispatchWorkItem?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupSearchFieldDelegate()
        handleAppearanceMode()
        setupUserCheckedStatus()
        setupBottomSheet()
        filterData(newString: selectedTxt)
    }
    
    private func setupSearchFieldDelegate() {
        
        self.tableView.register(UINib(nibName: "BookDetailCell", bundle: nil), forCellReuseIdentifier: "BookDetailCell")
        
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
        filterData(newString: "")
    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.checked = UserDefaults.standard.object(forKey: "checked") as? Bool ?? false
        if PlayerManager.shared.isPlaying {
            if comeFrom != ""{
                self.footerView.isHidden = false
            }
        }
      //  self.fetchPlaylistItems()
        guard let b = currentBok else{return}
        self.setupMiniPlayer(book: b)

    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if comeFrom == ""{
            
        }else{
            if p == "" {
                self.navigationController?.popToRootViewController(animated: false)
            }
        }
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
       }
    
    
    private func handleBottomSheetAction(_ action: BottomSheetViewController.ActionType) {
        let selectedItems = selectedIndices.compactMap { $0.row < playlistItems.count ? playlistItems[$0.row] : nil }
        
        switch action {
        case .delete:
            selectedItems.forEach { item in
                if let book = item as? Book {
                    handleDelete(book: book, alert: false)
                } else if let playlist = item as? Playlist {
                   handleDelete(playlist: playlist, alert: false)
                }
            }

        case .move:
            let sheet = UIAlertController(title: "\(selectedItems.count) items", message: nil, preferredStyle: .alert)
            sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

            sheet.addAction(UIAlertAction(title: "Existing Folder", style: .default) { _ in
                

                
                let playlistTableVC = PlaylistTableViewController()
                playlistTableVC.playlists = self.playlistItems.compactMap {
                    if let playlist = $0 as? Playlist, !selectedItems.contains(playlist) {
                        return playlist
                    }
                    return nil
                }
                playlistTableVC.items = selectedItems
                playlistTableVC.allowMoveToParent = self.playlist.parent != nil
                playlistTableVC.allowMoveToRoot = true
                playlistTableVC.parentPlaylist = self.playlist.parent
                playlistTableVC.delegate = self
                let navController = UINavigationController(rootViewController: playlistTableVC)
                self.present(navController, animated: true, completion: nil)
            })

            sheet.addAction(UIAlertAction(title: "New Folder", style: .default) { _ in
                selectedItems.forEach { selectedItem in
                    self.creatFolderAndInsertBooks(item: selectedItem)
                }
                
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
    
    private func lightModeEnabled() {
        searchTxt.attributedPlaceholder = NSAttributedString(string:"Search Your Books", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 40/255, green: 0, blue: 71/255, alpha: 1)])
        
    }
    private func darkModeEnabled() {
        searchTxt.attributedPlaceholder = NSAttributedString(string:"Search Your Books", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        //  self.topMenu.backgroundColor = #colorLiteral(red: 0.1098039216, green: 0.1098039216, blue: 0.1176470588, alpha: 1)
    }
    
    func fetchPlaylistItems() {
        let books = playlist.books?.array as? [LibraryItem] ?? []
        let childPlaylists = playlist.children?.allObjects as? [LibraryItem] ?? []
        
        
        let playlists = childPlaylists.compactMap { $0 as? Playlist }
        let bookItems = books.compactMap { $0 as? Book }
        
        
        let sortedPlaylists = playlists.sorted {
            ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
        }
        
       
        var sortedBooks: [Book] = []
        switch UserDetail.shared.getSortBy() {
        case "0":
            sortedBooks = bookItems.sorted {
                ($0.uploadTime ?? Date.distantFuture) > ($1.uploadTime ?? Date.distantPast)
            }
            self.sortByTxt.text = "Newest Upload"
        case "1":
            sortedBooks = bookItems.sorted {
                ($0.uploadTime ?? Date.distantFuture) < ($1.uploadTime ?? Date.distantPast)
            }
            self.sortByTxt.text = "Oldest Upload"
        case "2":
            sortedBooks = bookItems.sorted {
                ($0.recentPlayTime ?? Date.distantFuture) > ($1.recentPlayTime ?? Date.distantPast)
            }
            self.sortByTxt.text = "Recently Played"
        case "3":
            sortedBooks = bookItems.sorted {
                ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
            }
            self.sortByTxt.text = "Alphabetical"
        default:
            sortedBooks = bookItems
        }
        
        // Merge: playlists first, then sorted books
        self.playlistItems = sortedPlaylists + sortedBooks
        self.t_items = self.playlistItems
        if !checked {
            btnBookshowStatus.setImage( UIImage(named:"ic_outline-check-box-1"), for: .normal)
            
        } else {
            btnBookshowStatus.setImage(UIImage(named:"ic_outline-check-box"), for: .normal)
            
        }
        tableView.reloadData()
    }
    @IBAction func backBtn(_ sender:UIButton) {
        self.p = "1"
        self.navigationController?.popViewController(animated: true)
        
    }
    
    @IBAction func toggleSelectionMode(_ sender: UIButton) {
           isSelectionModeEnabled.toggle()
           tableView.reloadData()
       }
    @IBAction func btnCross_Action(_ sender: UIButton) {
        self.searchTxt.text = ""
        self.filterData(newString: "")
    }
    
    @IBAction func btnDot_Action(_ sender: UIButton) {
        
        self.topMenu.anchorView = sender
        self.topMenu.bottomOffset = CGPoint(x: -90, y: sender.bounds.height + 8)
        self.topMenu.textColor = .black
        self.topMenu.cornerRadius = 5.0
        self.topMenu.separatorColor = .clear
        self.topMenu.selectionBackgroundColor = .clear
        self.topMenu.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        self.topMenu.dataSource.removeAll()
        self.topMenu.dataSource.append(contentsOf: ["Bookmarks","History","Settings","Help & Feedback"])
        let imagesArr = ["bi_bookmark-fill","historyIcon","Settings","fluent_person-1x"]
       
        topMenu.cellNib = UINib(nibName: "DropDownCell", bundle: nil)
        topMenu.customCellConfiguration = { index, title, cell in
            
            guard let cell = cell as? MyCell1 else {
                return
            }
            cell.img1.image = UIImage(named: imagesArr[index])
            
        }
        self.topMenu.selectionAction = { [unowned self] (index, item) in
            if index == 0 {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "BookMarkVC") as! BookMarkVC
                vc.dataBack = { t in
                    PlayerManager.shared.jumpTo(t)
                }
                self.navigationController?.pushViewController(vc, animated: true)
            }else   if index == 1{
                
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "HistoryViewController") as! HistoryViewController
              
                self.navigationController?.pushViewController(vc, animated: true)
            }else if index == 2{
             //   Help & Feedback
                
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "SettingVC") as! SettingVC
           
                self.navigationController?.pushViewController(vc, animated: true)
            }else{
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "FeedbackVC") as! FeedbackVC
           
                self.navigationController?.pushViewController(vc, animated: true)
            }
        }
        self.topMenu.show()
        
    }
    
    @IBAction func addAction() {
        self.createPlaylist()
//        let alertController = UIAlertController(
//            title: nil,
//            message: "You can also add files via AirDrop. Send an audiobook file to your device and select SpeedListner from the list that appears.",
//            preferredStyle: .actionSheet
//        )
//        
//        alertController.addAction(UIAlertAction(title: "Import files", style: .default) { (_) in
//            self.importBook()
//        })
//        
//        alertController.addAction(UIAlertAction(title: "Create Folder", style: .default) { (_) in
//            self.createPlaylist()
//        })
//        
//        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//        
//        self.present(alertController, animated: true, completion: nil)
    }
    @IBAction func sortDot_Action(_ sender: UIButton) {
        
        sortMenu.dataSource = ["Newest Upload","Oldest Upload","Recently Played","Alphabetical"]
        sortMenu.anchorView = sender
        sortMenu.bottomOffset = CGPoint(x: 0, y: 50)
        sortMenu.show()
        
        sortMenu.selectionAction = { [weak self] (index: Int, item: String) in
            guard let self = self else { return }

            UserDetail.shared.savedSortBy("\(index)")
            let playlists = self.playlistItems.compactMap { $0 as? Playlist }
            let books = self.playlistItems.compactMap { $0 as? Book }

          
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

         
            self.playlistItems = sortedPlaylists + sortedBooks
            self.t_items = self.playlistItems

            DispatchQueue.main.async {
                self.tableView.setContentOffset(.zero, animated: true)
                self.tableView.reloadData()
            }
        }
    }
    
    
    
    private func handleDelete(book: Book, alert: Bool) {
        let performDeletion = {
         
            self.playlist?.removeFromBooks(book)
            NewDataMannagerClass.delete(book: book, from: self.library, or: self.playlist, deleteFile: true)
            NewDataMannagerClass.saveContext()
            self.fetchPlaylistItems()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.reloadData, object: nil)
        }

        if alert {
            let alertVC = UIAlertController(title: "Delete Book?", message: "Are you sure you want to delete '" + (book.title ?? "Untitled Book") + "' and all its notes?", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertVC.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                performDeletion()
            })
            self.present(alertVC, animated: true)
        } else {
            performDeletion()
        }
    }

    private func handleDelete(playlist: Playlist, alert: Bool) {
    
        func showCannotDeleteAlert(forPlaylist p: Playlist) {
            let title = "Cannot Delete Folder"
            let message = "This folder (\(p.title ?? "Untitled Folder")) contains audiobooks (possibly inside sub-folders). Please delete or move all audiobooks from the folder and its sub-folders before deleting it."
            let sheet = UIAlertController(title: title, message: message, preferredStyle: .alert)
            sheet.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(sheet, animated: true, completion: nil)
        }

       
        if playlistOrDescendantsContainBooks(playlist) {
            showCannotDeleteAlert(forPlaylist: playlist)
            return
        }

      
        let performDeletion = {
           
            self.playlist?.removeFromChildren(playlist)

            NewDataMannagerClass.delete(playlist: playlist, from: self.library, or: self.playlist, deleteBooks: false)
            NewDataMannagerClass.saveContext()
            self.fetchPlaylistItems()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.reloadData, object: nil)
        }

        if alert {
            // Show confirmation dialog before deleting the empty folder
            let alertVC = UIAlertController(title: "Delete Folder?", message: "Are you sure you want to delete '" + (playlist.title ?? "Untitled Folder") + "' and all its contents?", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertVC.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                // Re-check before performing deletion (in case something changed while the dialog was shown)
                if self.playlistOrDescendantsContainBooks(playlist) {
                    showCannotDeleteAlert(forPlaylist: playlist)
                    return
                }
                performDeletion()
            })
            self.present(alertVC, animated: true)
        } else {
            performDeletion()
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

extension LetterSearchVC: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - Table View Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      
            return filteredBooks.count
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
     
      
            let item = filteredBooks[indexPath.row]
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
    func toggleSelection(at indexPath: IndexPath) {
        if selectedIndices.contains(indexPath) {
            selectedIndices.remove(indexPath)
        } else {
            selectedIndices.insert(indexPath)
           
        }
   
            toggleBottomSheet()
      
        
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if checked {
            return UITableView.automaticDimension
        }else{
            return 50
        }
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard indexPath.section == 0 else { return nil }

        let item = self.filteredBooks[indexPath.row]

        let optionsAction = UIContextualAction(style: .normal, title: "Options") { [weak self] _, _, completionHandler in
            guard let self = self else {
                completionHandler(false)
                return
            }
            // Present custom bottom bar with actions
            self.showBottomOptionsForPlaylistItem(item, indexPath: indexPath)
            completionHandler(true)
        }

        optionsAction.backgroundColor = .gray
        let config = UISwipeActionsConfiguration(actions: [optionsAction])
        config.performsFirstActionWithFullSwipe = false
        return config
    }
    
    private func moveLibraryItem(item: LibraryItem, indexPath: IndexPath){
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

    
    
    private func creatFolderAndInsertBooks(item:LibraryItem){
        
        let alert = UIAlertController(title: "New Folder", message: "Enter Name Of  New Folder", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Folder Name"
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { _ in
            if let title = alert.textFields?.first?.text, !title.isEmpty {
                
           
                NewDataMannagerClass.insertPlaylists(title:title, into: nil, or: self.library, completion: { [weak self] playlist in
                    guard let self = self else{return}
                    
                        if item is Book{
                            NewDataMannagerClass.moveBook(item as! Book, from: self.playlist, or: nil, to: playlist, completion: {
                                self.fetchPlaylistItems()
                                
                            })
                        }else{
                            NewDataMannagerClass.movePlaylist(item as! Playlist, or: nil, from: self.playlist, to: playlist) {
                                self.fetchPlaylistItems()
                            }
                        }
                })
                
            }
        }
        
        alert.addAction(createAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      
            let item = filteredBooks[indexPath.row]
            
            if let subPlaylist = item as? Playlist {
                
                let playlistVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "NewPlaylistViewController") as! NewPlaylistViewController
                playlistVC.playlist = subPlaylist
                playlistVC.comeFrom = self.comeFrom
                playlistVC.p = self.p
                self.navigationController?.pushViewController(playlistVC, animated: true)
                
            } else if let book = item as? Book {
                self.setupPlayer(books: [book])
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
    
    @objc func playBtnTap(_ sender:UIButton){
        
       let item = self.filteredBooks[sender.tag]
        currentItem = item
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
            print(playlist.getRemainingBooks().count)
            self.setupPlayer(books: playlist.getRemainingBooks())
            
        }
        
    }
        
    func setupPlayer(books: [Book]) {
        // Make sure player is for a different book
        guard  let book = books.first else {return}
      
        if Int( book.currentTime) == Int(book.duration) {
            book.currentTime = 0.0
            NewDataMannagerClass.saveContext()
        }
        guard let currentBook = PlayerManager.shared.currentBook, currentBook.fileURL == book.fileURL else {
            // Handle loading new player
            self.loadPlayer(books: books)
            
            return
        }
        
        self.showPlayerView(book: book)
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
    func loadPlayer(books: [Book]) {
        guard let book = books.first else { return }
        
        guard NewDataMannagerClass.exists(book) else {
            self.showAlert(
                "File Missing!",
                message: "This Audiobook File Was Removed From Your Device. Import The File Again To Play The Audiobook.",
                style: .alert
            )
            
            return
        }
        
        //  MBProgressHUD.showAdded(to: self.view, animated: true)
        
        // Replace player with new one
        PlayerManager.shared.load(books) { (loaded) in
            guard loaded else {
                //MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                self.showAlert("File error!", message: "This Audiobook file couldn't be loaded. Make sure you're not using files with DRM protection (like .aax files)", style: .alert)
                return
            }
            self.showPlayerView(book: book)
            
            PlayerManager.shared.play()
        }
    }
    
    func showPlayerView(book: Book) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let playerVC = storyboard.instantiateViewController(withIdentifier: "PlayerViewController") as? PlayerViewController {
            playerVC.book = book
            
            PlayerManager.shared.play()
            self.tabBarController?.selectedIndex = 1
        }
    }
    
}

extension LetterSearchVC: PlaylistSelectionDelegate ,UITextFieldDelegate{
  
    
    
    func presentPlaylistTableView(item:LibraryItem) {
        let playlistTableVC = PlaylistTableViewController()
        playlistTableVC.playlists = self.playlistItems.compactMap {
            if let playlist = $0 as? Playlist, playlist.title != item.title {
                return playlist
            }
            return nil
        }
        playlistTableVC.item = item
        playlistTableVC.delegate = self
        playlistTableVC.allowMoveToParent = self.playlist.parent != nil
        playlistTableVC.allowMoveToRoot = true
        playlistTableVC.parentPlaylist = self.playlist.parent
        let navController = UINavigationController(rootViewController: playlistTableVC)
        present(navController, animated: true, completion: nil)
    }
    func didSelectPlaylist(_ playlist: Playlist, from items: [LibraryItem]?) {
          guard let items = items else { return }

          let library = NewDataMannagerClass.getLibrary()
          let currentPlaylist = self.playlist  // current context

          for item in items {
              if playlist.title == "__LIBRARY_ROOT__" {
                
                  if let book = item as? Book {
                      currentPlaylist?.removeFromBooks(book)
                      library.addToItems(book)
                  } else if let sub = item as? Playlist {
                      currentPlaylist?.removeFromChildren(sub)
                      library.addToItems(sub)
                  }
                  NewDataMannagerClass.saveContext()
              } else if playlist == currentPlaylist?.parent {
               
                  if let book = item as? Book {
                      currentPlaylist?.removeFromBooks(book)
                      playlist.addToBooks(book)
                  } else if let sub = item as? Playlist {
                      currentPlaylist?.removeFromChildren(sub)
                      playlist.addToChildren(sub)
                  }
                  NewDataMannagerClass.saveContext()
              } else {
                 
                  if let book = item as? Book {
                      NewDataMannagerClass.moveBook(book, from: currentPlaylist, or: library, to: playlist) {
                          NewDataMannagerClass.saveContext()
                      }
                  } else if let sub = item as? Playlist {
                      NewDataMannagerClass.movePlaylist(sub, or: library, from: currentPlaylist, to: playlist) {
                          NewDataMannagerClass.saveContext()
                      }
                  }
                  
              }
          }

          self.fetchPlaylistItems()
          NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.reloadData, object: nil)
      }

      // Optional: required if moving single item from a different screen
      func didSelectPlaylist(_ playlist: Playlist, from item: LibraryItem?) {
          if let item = item {
              self.didSelectPlaylist(playlist, from: [item])
          }
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

}
extension LetterSearchVC{
    
    private func setupUI(){
        searchTblV.delegate = self
        searchTblV.dataSource = self
        searchTblV.register(SearchResultTableViewCell.self, forCellReuseIdentifier: "SearchResultCell")
      //  playListTitle.text = playlist.title
        
        self.navigationItem.title = "Letter Search"
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didPressShowDetail(_:)))
        self.footerView.addGestureRecognizer(tapRecognizer)
        footerView.isUserInteractionEnabled = true
        
        //        self.footerView.isHidden = true
        self.footerView.clipsToBounds = true
        self.footerView.layer.cornerRadius = 20
        self.footerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBookPlay), name: Notification.Name.AudiobookPlayer.bookPlayed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBookPause), name: Notification.Name.AudiobookPlayer.bookPaused, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBookPause), name: Notification.Name.AudiobookPlayer.bookEnd, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBookStop(_:)), name: Notification.Name.AudiobookPlayer.bookStopped, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.bookChange(_:)), name: Notification.Name.AudiobookPlayer.bookChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.bookReady(_:)), name: Notification.Name.AudiobookPlayer.bookReady, object: nil)
        
        tableView.delegate = self
        tableView.dataSource = self
     //   self.playlistName.append(self.playlist.title ?? "unknown")
        //fetchPlaylistItems()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.addTarget(self, action: #selector(valueChange(_:)), for: .editingChanged)
    }
    
    
    @objc func valueChange(_ textField:UITextField){
    //    self.filterData(newString: textField.text ?? "")
    }
    
    func filterData(newString: String) {
        // ---- debounce filtering (1s) ----
        debounceWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }

            if !newString.isEmpty {
                let searchPrefix = String(newString.prefix(1)).lowercased()

                let filteredArray = t_items.filter { item in
                    let titleWords = item.title?.lowercased().split(separator: " ") ?? []
                    let authorWords = (item as? Book)?.author?.lowercased().split(separator: " ") ?? []
                    let titleMatch = titleWords.contains { $0.hasPrefix(searchPrefix) }
                    let authorMatch = authorWords.contains { $0.hasPrefix(searchPrefix) }
                    return titleMatch || authorMatch
                }
                self.playlistItems = filteredArray
            } else {
                self.playlistItems = self.t_items
            }

            filteredBooks = getAllBooks(from: library).filter {
                $0.title?.localizedCaseInsensitiveContains(newString) == true
            }

            let rowHeight: CGFloat = 40
            let maxHeight: CGFloat = 200
            let calculatedHeight = min(CGFloat(filteredBooks.count) * rowHeight, maxHeight)

          //  searchTblVH.constant = calculatedHeight
           // searchTblV.isHidden = filteredBooks.isEmpty

      //      self.searchTblV.reloadData()
            self.tableView.reloadData()
        }
        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)

        // ---- debounce keyboard hide (10s idle) ----
        keyboardHideWorkItem?.cancel()
        let hideItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // hides whatever is first responder (your search field)
                self.view.endEditing(true)
            }
        }
        keyboardHideWorkItem = hideItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: hideItem)
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
    
    @objc func importBook() {
        
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        present(documentPicker, animated: true, completion: nil)
    }
    
    @objc func createPlaylist() {
        let alert = UIAlertController(title: "New Folder", message: "Enter Name Of New Folder", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Folder Name"
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { _ in
            if let title = alert.textFields?.first?.text, !title.isEmpty {
                
                NewDataMannagerClass.insertPlaylists(title: title, into: self.playlist, or: nil, completion: {_ in 
                    self.fetchPlaylistItems()
                })
                
            }
        }
        
        alert.addAction(createAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    
    @objc  func onBookPlay() {
        self.tableView.reloadData()
        setPlayImage()
        guard
            let currentBook = PlayerManager.shared.currentBook
           // let index = self.playlist.itemIndex(with: currentBook.fileURL),
           // let bookCell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? BookDetailCell
        else {
            return
        }
        
       
    }
    
    @objc  func onBookPause() {
        setPlayImage()
        guard
            let currentBook = PlayerManager.shared.currentBook,
            let index = self.playlist.itemIndex(with: currentBook.fileURL),
            let bookCell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? BookDetailCell
        else {
            return
        }
        
        bookCell.playbackState = .paused
    }
    
    @objc  func onBookStop(_ notification: Notification) {
        setPlayImage()
        guard
            let userInfo = notification.userInfo,
            let book = userInfo["book"] as? Book,
            let index = self.playlist.itemIndex(with: book.fileURL),
            let bookCell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? BookDetailCell
        else {
            return
        }
        
        bookCell.playbackState = .stopped
    }
    
    @IBAction func didPressPlay(_ sender: UIButton){
        PlayerManager.shared.playPause()
        self.setPlayImage()
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
    
    @IBAction func miniplayerBookmarksBtn_Action(_ sender: UIButton){
        
        let vc: BookmarkPopUpVC = self.storyboard?.instantiateViewController(withIdentifier: "BookmarkPopUpVC") as! BookmarkPopUpVC
        vc.playerstaus = PlayerManager.shared.isPlaying
        self.addChild(vc)
        vc.view.frame = self.view.frame
        self.view.addSubview(vc.view)
        self.view.bringSubviewToFront(vc.view)
        vc.didMove(toParent: self)
        
    }
}

extension LetterSearchVC {
    
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
        self.footerTitleLabel.text = (title ?? "unknown") + " - " + author
       self.setPlayImage()
    }
    
    func setPlayImage(){
        let miniPlayImage = UIImage(named: "29")
        let miniPauseButton = UIImage(named: "21")
        if PlayerManager.shared.isPlaying {
            self.footerPlayButton.setImage(miniPauseButton, for: UIControl.State())
            
        }else{
            self.footerPlayButton.setImage(miniPlayImage, for: UIControl.State())
        }
    }
    
}

extension LetterSearchVC: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        processFilesSequentially(at: urls, index: 0)
    }
    
    func processFilesSequentially(at urls: [URL], index: Int) {
        guard index < urls.count else {
            NewDataMannagerClass.saveContext()
            self.fetchPlaylistItems()
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
            NewDataMannagerClass.insertBooks(from: [bookUrl], into: self.playlist, or: self.library) {
                DispatchQueue.main.async {
                    completion()
                }
            }
        }
    }
}

extension LetterSearchVC:UICollectionViewDelegate,UICollectionViewDataSource{
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
            self.filterData(newString:"")
        }else{
            self.selectedTxt = AlphabetArr[indexPath.row]
            self.filterData(newString: self.selectedTxt)
        }
        
        self.collecV.reloadData()
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

        
}
extension LetterSearchVC {
    private func handleAppearanceMode() {
        if traitCollection.userInterfaceStyle == .dark {
            darkModeEnabled()
            print("Dark Mode is active")
        } else {
            lightModeEnabled()
            print("Light Mode is active")
        }
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        switch traitCollection.userInterfaceStyle {
        case .dark: darkModeEnabled()
        case .light: fallthrough
        case .unspecified: fallthrough
        default: lightModeEnabled()
        }
    }
    func showBottomOptionsForPlaylistItem(_ item: LibraryItem, indexPath: IndexPath) {
        let library = NewDataMannagerClass.getLibrary()
        let bar = BottomOptionsBarPlaylist()

        // Remove from folder
        bar.onRemoveFromFolder = { [weak self] in
            guard let self = self else { return }
            bar.dismiss {
                if let book = item as? Book {
                    // Remove book from current playlist and add to library
                    self.playlist?.removeFromBooks(book)
                    library.addToItems(book)
                } else if let pl = item as? Playlist {
                    // Remove playlist from current playlist and add to library
                    self.playlist?.removeFromChildren(pl)
                    library.addToItems(pl)
                }
                NewDataMannagerClass.saveContext()
                self.fetchPlaylistItems()
                NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.reloadData, object: nil)
            }
        }

        // Move
        bar.onMove = { [weak self] in
            guard let self = self else { return }
            bar.dismiss {
                self.moveLibraryItem(item: item, indexPath: indexPath)
            }
        }

        // Delete completely
        bar.onDeleteCompletely = { [weak self] in
            guard let self = self else { return }
            bar.dismiss {
                if let book = item as? Book {
                    if book == PlayerManager.shared.currentBook {
                        PlayerManager.shared.stop()
                    }
                    // confirm delete book
                    let confirm = UIAlertController(
                        title: "All The Notes Associated With This Book Will Be Deleted!",
                        message: "Do You Really Want To Delete :\(book.title ?? "")?",
                        preferredStyle: .alert
                    )
                    confirm.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    confirm.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                        NewDataMannagerClass.delete(book: book, from: NewDataMannagerClass.getLibrary(), or: self.playlist, deleteFile: true)
                        NewDataMannagerClass.saveContext()
                        self.fetchPlaylistItems()
                        NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.reloadData, object: nil)
                    }))
                    self.present(confirm, animated: true, completion: nil)

                } else if let pl = item as? Playlist {
                    // block delete if subtree contains books
                    if self.playlistOrDescendantsContainBooks(pl) {
                        let sheet = UIAlertController(
                            title: "Cannot Delete Folder",
                            message: """
                            This Folder Contains Audiobooks (Possibly Inside Sub-Folders).Please Delete Or Move All Audiobooks First Before Deleting This Folder.
                            """,
                            preferredStyle: .alert
                        )
                        sheet.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(sheet, animated: true, completion: nil)
                        return
                    }

                    // confirm delete empty folder
                    let confirm = UIAlertController(
                        title: "Delete Folder?",
                        message: "Are you sure you want to delete \"\(pl.title ?? "")\"?",
                        preferredStyle: .alert
                    )
                    confirm.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    confirm.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                        NewDataMannagerClass.delete(
                            playlist: pl,
                            from: NewDataMannagerClass.getLibrary(),
                            or: self.playlist,
                            deleteBooks: false
                        )
                        NewDataMannagerClass.saveContext()
                        self.fetchPlaylistItems()
                        NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.reloadData, object: nil)
                    }))
                    self.present(confirm, animated: true, completion: nil)
                }
            }
        }

        // Cancel
        bar.onCancel = {
            bar.dismiss()
        }

        bar.present(in: self.view)
    }
    
}

