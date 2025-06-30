//
//  UploadBookVC.swift
//  SpeedListner
//
//  Created by Satyam Dwivedi on 16/06/23.



import UIKit
import DropDown
import AVFAudio
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
        self.addAction()
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
//        alertController.addAction(UIAlertAction(title: "Upload AudioBook(.aax) files", style: .default) { (_) in
//            self.cloudFilePicker.browseLocalFiles(in: self) { url in
//                guard let url = url else {return}
//                let parameters = [
//                    [
//                        "key": "aax_file",
//                        "src": url,
//                        "type": "file"
//                    ]
//                ]
//
//                let uploadDoc = UploadDoc()
//                uploadDoc.startUpload(parameters: parameters) { result in
//                    switch result {
//                    case .success(let success):
//                        print("Upload successful: \(success)")
//                        self.loadLibrary()
//                    case .failure(let error):
//                        print("Upload failed: \(error.localizedDescription)")
//                    }
//                }
//            }
//        })
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        self.present(alertController, animated: true, completion: nil)
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
        if sender.tag == 1 {
            self.showAlert(for: "Please Suscribe to our plan for use this feature")
           
        }else{
            self.addAction()
//            let sheet = UIAlertController(title: "Import Books", message: nil, preferredStyle: .actionSheet)
//
//            let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
//            let localButton = UIAlertAction(title: "From Files", style: .default) { (action) in
//                let providerList = UIDocumentMenuViewController(documentTypes: ["public.audio"], in: .import)
//                providerList.delegate = self;
//
//                providerList.popoverPresentationController?.sourceView = self.view
//                providerList.popoverPresentationController?.sourceRect = CGRect(x: Double(self.view.bounds.size.width / 2.0), y: Double(self.view.bounds.size.height-45), width: 1.0, height: 1.0)
//                self.present(providerList, animated: true, completion: nil)
//            }
//
//            let airdropButton = UIAlertAction(title: "AirDrop", style: .default) { (action) in
//                self.showAlert("AirDrop", message: "Make sure AirDrop is enabled.\n\nOnce you transfer the file to your device via AirDrop, choose 'SpeedListner' from the app list that will appear", style: .alert)
//            }
//
//            sheet.addAction(localButton)
//            sheet.addAction(airdropButton)
//            sheet.addAction(cancelButton)
//
//            sheet.popoverPresentationController?.sourceView = self.view
//            sheet.popoverPresentationController?.sourceRect = CGRect(x: Double(self.view.bounds.size.width / 2.0), y: Double(self.view.bounds.size.height-45), width: 1.0, height: 1.0)
//
//            self.present(sheet, animated: true, completion: nil)
        }
        
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
    func presentImportFilesAlert() {
        let providerList = UIDocumentMenuViewController(documentTypes: ["public.audio"], in: .import)
        providerList.delegate = self
        self.present(providerList, animated: true, completion: nil)

        if #available(iOS 11.0, *) {
          //  providerList.allowsMultipleSelection = true
        }

       // self.present(providerList, animated: true, completion: nil)
    }
}
extension UploadBookVC :UIDocumentPickerDelegate{
//    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
//        let userInfo = ["fileURL": url]
//        NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.libraryOpenURL, object: nil, userInfo: userInfo)
//    }
     func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
                    let userInfo = ["fileURL": url]
                    NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.libraryOpenURL, object: nil, userInfo: userInfo)
                }
        
                self.tabBarController?.selectedIndex = 0
       
        
    }
//    func documentPickerdocumentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
//        for url in urls {
//            let userInfo = ["fileURL": url]
//            NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.libraryOpenURL, object: nil, userInfo: userInfo)
//        }
//    }
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
