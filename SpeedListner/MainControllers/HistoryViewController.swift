//
//  HistoryViewController.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 04/07/25.
//

import UIKit
import CoreData

class HistoryViewController:UIViewController {
    
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerImageView: UIImageView!
    @IBOutlet weak var footerTitleLabel: UILabel!
    @IBOutlet weak var footerPlayButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var collecV: UICollectionView!
    @IBOutlet weak var btnBookshowStatus: UIButton!
    @IBOutlet weak var searchTxt: UITextField!
   
    
    let queue = OperationQueue()
 
    var comeFrom = ""
    var p = ""
    private var playedBooks: [Book] = []

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
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchFieldDelegate()
        fetchPlayedBooks()
        self.setupUI()
        setupSearchFieldDelegate()
        setupUserCheckedStatus()
        if let book = PlayerManager.shared.currentBook {
            setupMiniPlayer(book:book)
        }
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.checked = UserDefaults.standard.object(forKey: "checked") as? Bool ?? false
        if PlayerManager.shared.isPlaying {
            if comeFrom != ""{
                self.footerView.isHidden = false
            }
        }
        if let book = PlayerManager.shared.currentBook {
            setupMiniPlayer(book:book)
        }
   
      

    }
    
    private func setupSearchFieldDelegate() {
        self.tableView.register(UINib(nibName: "BookDetailCell", bundle: nil), forCellReuseIdentifier: "BookDetailCell")
        
        searchTxt.delegate = self
        searchTxt.clearButtonMode = .never
        let clearButton = UIButton(type: .custom)
        clearButton.setBackgroundImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        clearButton.tintColor = .gray
        clearButton.frame = CGRect(x: 0, y: 0, width: 36, height: 36)
        clearButton.addTarget(self, action: #selector(clearSearchText), for: .touchUpInside)
        
        searchTxt.rightView = clearButton
        searchTxt.rightViewMode = .always
    }
    
    @objc private func clearSearchText() {
        searchTxt.text = ""
//        filterData(newString: "")
    }
    private func fetchPlayedBooks() {
            let context = NewDataMannagerClass.persistentContainer.viewContext
            let request: NSFetchRequest<Book> = Book.fetchRequest()
            request.predicate = NSPredicate(format: "recentPlayTime != nil")
            request.sortDescriptors = [NSSortDescriptor(key: "recentPlayTime", ascending: false)]

            do {
                playedBooks = try context.fetch(request)
                tableView.reloadData()
            } catch {
                print("Failed to fetch played books: \(error)")
            }
        }
}
extension HistoryViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - Table View Data Source
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
      
            return playedBooks.count
        }
    
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
            let item = playedBooks[indexPath.row]
    
        
            if checked {
                let cell = tableView.dequeueReusableCell(withIdentifier: "BookDetailCell", for: indexPath) as! BookDetailCell
                cell.type =  .book
                cell.playbackState = .stopped
                cell.lbl_BookName.text = item.title
                cell.img.image = item.artwork
                cell.stackBgView.backgroundColor = .lightGray
                cell.btnPlay.tag = indexPath.row
                cell.btnPlay.addTarget(self, action: #selector(playBtnTap(_:)), for: .touchUpInside)
                
               
                    cell.lbl_AutherName.isHidden = false
                    cell.lbl_AutherName.text = item.author
                    cell.lbl_comlition.text = "\(Int(round(item.percentCompleted)))%"
                    cell.lbl_comlition.isHidden = false
                    cell.lbl_subFolderCount.isHidden = true
                    cell.btnPlay.isHidden = false
            
                
                return cell
            } else {
                let cell = tableView.dequeueReusableCell(withIdentifier: "MyBookCell", for: indexPath) as! MyBookCell
                cell.lblBookName.text = item.title
             cell.lblBookAuthor.text = "\(Int(round(item.percentCompleted)))%"
                    cell.folderIcon.isHidden = true
                    cell.lblBookAuthor.isHidden = false

                cell.viewBgView.backgroundColor = .lightGray
                
                cell.selectionStyle = .none
                
                return cell
            }
        }
        
    


    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if checked {
            return UITableView.automaticDimension
        }else{
            return 50
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
        
       let item = self.playedBooks[sender.tag]
        currentItem = item
     
            print(item.currentTime,item.duration,"duratin matching")
            if Int( item.currentTime) == Int(item.duration) {
                item.currentTime = 0.0
                NewDataMannagerClass.saveContext()
            }
            self.setupPlayer(books: [item])
            

        
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
        
    
    func loadPlayer(books: [Book]) {
        guard let book = books.first else { return }
        
        guard NewDataMannagerClass.exists(book) else {
            self.showAlert("File missing!", message: "This book’s file was removed from your device. Import the file again to play the book", style: .alert)
            
            return
        }
        
        PlayerManager.shared.load(books) { (loaded) in
            guard loaded else {
                //MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                self.showAlert("File error!", message: "This book's file couldn't be loaded. Make sure you're not using files with DRM protection (like .aax files)", style: .alert)
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
extension HistoryViewController:UITextFieldDelegate{
  
    
      
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
extension HistoryViewController{
    
    private func setupUI(){

        
       
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
       
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.addTarget(self, action: #selector(valueChange(_:)), for: .editingChanged)
    }
    
    
    @objc func valueChange(_ textField:UITextField){
        self.filterData(newString: textField.text ?? "")
    }
    @IBAction func backBtn(_ sender:UIButton) {
        self.navigationController?.popViewController(animated: true)
        
    }
    
    func filterData(newString: String) {
        // Cancel any previous work item
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

                //self.playlistItems = filteredArray
            } else {
              //  self.playlistItems = self.t_items
            }

//            filteredBooks = getAllBooks(from: library).filter {
//                   $0.title?.localizedCaseInsensitiveContains(newString) == true
//               }
            let rowHeight: CGFloat = 40 // or your cell height
                let maxHeight: CGFloat = 200
                let calculatedHeight = min(CGFloat(filteredBooks.count) * rowHeight, maxHeight)

            self.tableView.reloadData()
            DispatchQueue.main.async {
                      UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                  }
        }

        debounceWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: workItem)
    }
    
    
    
    @objc  func onBookPlay() {
        self.tableView.reloadData()
        setPlayImage()
      
    }
    
    @objc  func onBookPause() {
        setPlayImage()
    }
    
    @objc  func onBookStop(_ notification: Notification) {
        setPlayImage()
        
        
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
extension HistoryViewController {
    
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
extension HistoryViewController:UICollectionViewDelegate,UICollectionViewDataSource{
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
