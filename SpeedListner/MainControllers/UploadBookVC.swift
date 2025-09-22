//
//  UploadBookVC.swift
//  SpeedListner
//
//  Created by Satyam Dwivedi on 16/06/23.



import UIKit
import DropDown
import AVFAudio
import AVFoundation
class UploadBookVC: UIViewController, UITableViewDelegate, UITableViewDataSource {
  
    
    
    //for mini player
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerImageView: UIImageView!
    @IBOutlet weak var footerTitleLabel: UILabel!
    @IBOutlet weak var tbl_bottom_con: NSLayoutConstraint!
    @IBOutlet weak var footerPlayButton: UIButton!
    @IBOutlet weak var uploadButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    var index = Int()
    let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
    let topMenu = DropDown()
    var playlist: Playlist!
    var items1 =  [LibraryItem]()
    var library: Library!
    var items =  [LibraryItem]()
    let queue = OperationQueue()
    lazy var dropDowns: [DropDown] = {
        return [
            self.topMenu
        ]
    }()
    
    //keep in memory images to toggle play/pause
    
    let miniPlayImage = UIImage(named: "29")
    let miniPauseButton = UIImage(named: "21")
    
    let documentsPath1 = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadLibrary(title: "")
      // self.footerView.isHidden = true
     //  self.tableView.tableFooterView = UIView()
    //   set tap handler to show detail on tap on footer view
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didPressShowDetail(_:)))
        self.footerView.addGestureRecognizer(tapRecognizer)
        footerView.isUserInteractionEnabled = true
        self.footerView.clipsToBounds = true
        self.footerView.layer.cornerRadius = 20
        self.footerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.play_pauseImgSet(_:)), name: Notification.Name.AudiobookPlayer.play_pause, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleAudioInterruptions(_:)), name: AVAudioSession.interruptionNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.newPlayListAdded(_:)), name: Notification.Name.AudiobookPlayer.newPlayListAdded, object: nil)
        
        //Mini
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBookPlay), name: Notification.Name.AudiobookPlayer.bookPlayed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBookPause), name: Notification.Name.AudiobookPlayer.bookPaused, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBookPause), name: Notification.Name.AudiobookPlayer.bookEnd, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBookStop(_:)), name: Notification.Name.AudiobookPlayer.bookStopped, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.bookChange(_:)), name: Notification.Name.AudiobookPlayer.bookChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.bookReady(_:)), name: Notification.Name.AudiobookPlayer.bookReady, object: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        

        if PlayerManager.shared.isPlaying {
            self.footerView.isHidden = false
        }
     
        self.loadLibrary(title: "")
        self.subscribedPlanDetail()
        guard let b = currentBok else{return}
        self.setupMiniPlayer(book: b)
    }
    @objc func newPlayListAdded(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let title = userInfo["title"] as?  String else {
                return
        }
        self.loadLibrary(title: title)
    
    }
    func loadLibrary(title:String) {
        self.library = NewDataMannagerClass.getLibrary()
        items1.removeAll()
        self.items.forEach { item in
            if item is Playlist {
                
            }else if let i = item as? Playlist {
                    self.items1.append(i)
                }
            
        }
    
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
      
       
    }
    @IBAction func uploadFileBtn(_ sender: Any) {
        self.presentImportFilesAlert()
    }
    
    private func presentImportFilesAlert() {
        
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.audio])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        present(documentPicker, animated: true, completion: nil)
        
    }

    private func creatFolder(){
        
        let alert = UIAlertController(title: "New Playlist", message: "Enter a title for the playlist", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "Playlist Title"
        }
        
        let createAction = UIAlertAction(title: "Create", style: .default) { _ in
            if let title = alert.textFields?.first?.text, !title.isEmpty {
                
                NewDataMannagerClass.insertPlaylists(title:title, into: nil, or: self.library, completion: { [weak self] _ in
                    guard let self = self else{return}
                    self.tabBarController?.selectedIndex = 0
                })
                
            }
        }
        
        alert.addAction(createAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true, completion: nil)
    }
    @IBAction func btnDot_Action(_ sender: UIButton) {
        
        self.topMenu.anchorView = sender
        self.topMenu.bottomOffset = CGPoint(x: -90, y: sender.bounds.height + 8)
        self.topMenu.textColor = .black
        self.topMenu.cornerRadius = 5.0
        //        self.topMenu.borderWidth = 1
        //        self.topMenu.borderColor = #colorLiteral(red: 0.3842016757, green: 0.2161925137, blue: 0.7387148142, alpha: 1)
        self.topMenu.separatorColor = .clear
        self.topMenu.selectionBackgroundColor = .clear
        self.topMenu.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        self.topMenu.dataSource.removeAll()
        self.topMenu.dataSource.append(contentsOf: ["Bookmarks","Settings","Help & Feedback"])
        let imagesArr = ["bi_bookmark-fill","Settings","fluent_person-1x"]
        //  let imagesArr = ["Vector","Settings","bi_bookmark-fill"]
        topMenu.cellNib = UINib(nibName: "DropDownCell", bundle: nil)
        topMenu.customCellConfiguration = { index, title, cell in
            
            guard let cell = cell as? MyCell1 else {
                return
            }
            cell.img1.image = UIImage(named: imagesArr[index])
            // UIImage(systemName: imagesArr[index])
            // cell.lbltitle.text = aArr[index]
        }
        self.topMenu.selectionAction = { [unowned self] (index, item) in
            if index == 0 {
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "BookMarkVC") as! BookMarkVC
                vc.dataBack = { t in
                    PlayerManager.shared.jumpTo(t)
                }
                self.navigationController?.pushViewController(vc, animated: true)
            }else   if index == 1{
                
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "SettingVC") as! SettingVC
                //self.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(vc, animated: true)
            }else{
             //   Help & Feedback
                
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "FeedbackVC") as! FeedbackVC
                //self.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(vc, animated: true)
            }
            //
        }
        self.topMenu.show()
        
    }
    
    //Playback may be interrupted by calls. Handle pause
    @objc func play_pauseImgSet(_ notification:Notification){
      
        
    }
    /**
     * Set play or pause image on button
     */
    func setPlayImage(){
        if PlayerManager.shared.isPlaying {
            self.footerPlayButton.setImage(self.miniPauseButton, for: UIControl.State())
            
        }else{
            self.footerPlayButton.setImage(self.miniPlayImage, for: .normal)
        }
        if PlayerManager.shared.miniPlayerIsHidden{
            self.tbl_bottom_con.constant = 90
            self.footerView.isHidden = false
        }else{
            self.tbl_bottom_con.constant = 0
            self.footerView.isHidden = false
        }
    }
    
    @objc func handleAudioInterruptions(_ notification:Notification){
        
        
    }
    
    
    @IBAction func didPressPlay(_ sender: UIButton){
        PlayerManager.shared.playPause()
        self.setPlayImage()
    }
    
    
    @IBAction func miniplayerCrossBtn_Action(_ sender: UIButton){
        PlayerManager.shared.miniPlayerIsHidden = true
     //   self.footerView.isHidden = true
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
    
    @IBAction func didPressShowDetail(_ sender: UIButton) {
        if d {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let playerVC = storyboard.instantiateViewController(withIdentifier: "PlayerViewController2") as! PlayerViewController
            guard let b = currentBok else {return}
            playerVC.book = b
            //PlayerManager2.shared.playPause()
            self.tabBarController?.selectedIndex = 1

           // self.present(playerVC, animated: true)
        }else{
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let playerVC = storyboard.instantiateViewController(withIdentifier: "PlayerViewController") as! PlayerViewController
            guard let b = currentBok else {return}
            playerVC.book = b
           // PlayerManager2.shared.playPause()
            self.tabBarController?.selectedIndex = 1

           // self.present(playerVC, animated: true)
        }
        
      
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return items1.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    
        let item = self.items1[indexPath.row] as? Playlist
        let cell = tableView.dequeueReusableCell(withIdentifier: "BookDetailsCell", for: indexPath) as! BookDetailsCell
        
        cell.lbl_BookName.text = item?.title
        cell.lbl_AutherName.text = item?.info().0
        cell.img.image = item?.artwork
        cell.btnPlay.isHidden = true
        cell.type = .playlist
        
        if item?.info().0 == "0" {
            cell.folderIcon_img.isHidden = true
            cell.lbl_AutherName.text = "\(0) Files"
        }else{
            cell.folderIcon_img.isHidden = false
            cell.lbl_AutherName.text = item?.info().0
        }

    return cell
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = self.items1[indexPath.row]

        guard let book = item as? Book else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
             if let playlist = item as? Playlist, let playlistVC = storyboard.instantiateViewController(withIdentifier: "NewPlaylistViewController") as? NewPlaylistViewController {
                           
                            playlistVC.playlist = playlist
                            playlistVC.comeFrom = ""
            self.navigationController?.pushViewController(playlistVC, animated: true)
            }
            
            return
        }
//        self.setupPlayer(books: [book])
        }

    
}

extension UploadBookVC:UIDocumentMenuDelegate {
    @IBAction func didPressImportOptions(_ sender: UIBarButtonItem){
//        if sender.tag == 1 {
//            self.showAlert(for: "Please Suscribe to our plan for use this feature")
//           
//        }else{
//           // self.addAction()
//
//        }
        
    }
    
    func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        //show document picker
        documentPicker.delegate = self;
        documentPicker.allowsMultipleSelection = false
        documentPicker.popoverPresentationController?.sourceView = self.view
        documentPicker.popoverPresentationController?.sourceRect = CGRect(x: Double(self.view.bounds.size.width / 2.0), y: Double(self.view.bounds.size.height-45), width: 1.0, height: 1.0)
        self.present(documentPicker, animated: true, completion: nil)
    }


//extension UploadBookVC:UIDocumentPickerDelegate {
//    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
//
//        //Documentation states that the file might not be imported due to being accessed from somewhere else
//        do {
//            try FileManager.default.attributesOfItem(atPath: url.path)
//        }catch{
//            self.showAlert("Error", message: "File import fail, try again later", style: .alert)
//            return
//        }
//
//        let trueName = url.lastPathComponent
//        var finalPath = self.documentsPath+"/"+(trueName)
//
//        if trueName.contains(" ") {
//            finalPath = finalPath.replacingOccurrences(of: " ", with: "_")
//        }
//
//        let fileURL = URL(fileURLWithPath: finalPath.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!)
//
//        do {
//            try FileManager.default.moveItem(at: url, to: fileURL)
//                //print(trueName,"INUploads")
//            UserDefaults.standard.set(Date(), forKey: trueName.replacingOccurrences(of: " ", with: "_") + "_upload")
//            print(Date(),trueName + "_upload","WhileUploading")
//
//        }catch{
//
//            self.showAlert("Error", message: "File import fail, try again later", style: .alert)
//
//            return
//        }
//        self.tabBarController?.selectedIndex = 0
//        NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.updateListOfFiles, object: nil)
//    }
    func subscribedPlanDetail(){
        // self.uploadButton.isUserInteractionEnabled = false
        //self.loading.showActivityLoading(uiView: self.view)

         var para  = [String:Any]()


         para["user_id"] = UserDetail.shared.getUserId()
        

        WebService.shared.postService("https://speedlistener.yesitlabs.co/api/user_subscription_details", andParameter: para, withCompletion: { json, response in
            
             guard let dict = json.dictionaryObject else{ return }
             self.uploadButton.isUserInteractionEnabled = true
             if let status = dict["success"] as? Bool, status == true,let data = dict["data"] as? NSArray,let dic = data[0] as? NSDictionary {
                 if let d =  dic["plan_expiry_check"] as? Int,d == 0{
                     self.uploadButton.tag = 0
                     
                 }else{
                     self.uploadButton.tag = 1
                 }
                
             }else {
                 self.uploadButton.tag = 1

             }
         })
     }
}
extension UploadBookVC:TapOnOptions{
    func tapped(conditionValue: Int) {
        self.presentedViewController?.dismiss(animated: true)
        switch conditionValue {
        case 0:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "GetProfileVC") as! GetProfileVC
            self.navigationController?.pushViewController(vc, animated: true)
        case 1:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "SettingVC") as! SettingVC
           // self.hidesBottomBarWhenPushed = true
            self.navigationController?.pushViewController(vc, animated: true)
        case 2:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "BookMarkVC") as! BookMarkVC
            vc.dataBack = { t in
               
            }
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
    
}

extension UploadBookVC{

    func presentCreatePlaylistAlert(_ namePlaceholder: String = "Name", handler: ((_ title: String) -> Void)?) {
        let playlistAlert = UIAlertController(
            title: "Create a new Folder",
            message: "Files in Folder are automatically played one after the other",
            preferredStyle: .alert
        )

        playlistAlert.addTextField(configurationHandler: { (textfield) in
            textfield.placeholder = namePlaceholder
        })

        playlistAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        playlistAlert.addAction(UIAlertAction(title: "Create", style: .default, handler: { _ in
            let title = playlistAlert.textFields!.first!.text!

            handler?(title)
        }))

        self.present(playlistAlert, animated: true, completion: nil)
    }
    
}

extension UploadBookVC {
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
        let title = book.title ?? "Unknown"
         let author = book.author ?? "Unknown"
        self.footerImageView.image = book.artwork
        self.footerTitleLabel.text = title + " - " + author
         self.tbl_bottom_con.constant = 90
                self.setPlayImage()
    }
    @objc private func onBookPlay() {
        setPlayImage()
        self.tableView.reloadData()
        guard
            let book = PlayerManager.shared.currentBook,
            let index = self.library.itemIndex(with: book.fileURL),
            let bookCell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? BookDetailsCell
        else {
            return
        }
       
        bookCell.playbackState = .playing
    }

    @objc private func onBookPause() {
        setPlayImage()
        guard
            let book = PlayerManager.shared.currentBook,
            let index = self.library.itemIndex(with: book.fileURL),
            let bookCell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? BookDetailsCell
        else {
            return
        }
       
        bookCell.playbackState = .paused
    }
    @objc func onBookStop(_ notification: Notification) {
        setPlayImage()
        guard
            let userInfo = notification.userInfo,
            let book = userInfo["book"] as? Book,
            let index = self.library.itemIndex(with: book.fileURL),let bookCell = self.tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? BookDetailsCell
        else {
            return
        }
       
        bookCell.playbackState = .stopped

      //  bookCell.playbackState = .stopped
    }

}
extension UploadBookVC: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        processFilesSequentially(at: urls, index: 0)
    }

    func processFilesSequentially(at urls: [URL], index: Int) {
        guard index < urls.count else {
            NewDataMannagerClass.saveContext()
//            self.loadLibrary()
            DispatchQueue.main.async {
                self.tabBarController?.selectedIndex = 0
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
                            completion() // skip this file
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
}
