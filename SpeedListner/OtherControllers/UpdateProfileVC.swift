//
//  UpdateProfileVC.swift
//  SpeedListners
//
//  Created by ravi on 9/08/22.
//

import UIKit
//import AudioStreaming

import MediaPlayer


class UpdateProfileVC: UIViewController, DelegateforResetPassword,UIImagePickerControllerDelegate,UINavigationControllerDelegate,UITextFieldDelegate {
    var imagePicker = UIImagePickerController()
    func MethodforPop() {
        if self.children.count > 0 {
            let viewControllers:[UIViewController] = self.children
            for viewContoller in viewControllers{
                self.tabBarController?.tabBar.isHidden = false
                viewContoller.willMove(toParent: nil)
                viewContoller.view.removeFromSuperview()
                viewContoller.removeFromParent()
            }
        }
    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var txt_email: UITextField!
    @IBOutlet weak var txt_phone: UITextField!
    
    //for mini player
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerView1: UIView!
    @IBOutlet weak var footerImageView: UIImageView!
    @IBOutlet weak var footerTitleLabel: UILabel!
    @IBOutlet weak var footerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var footerPlayButton: UIButton!
    
    //keep in memory images to toggle play/pause
    let miniPlayImage = UIImage(named: "29")
    let miniPauseButton = UIImage(named: "21")
    
    @IBOutlet weak var txt_name: UITextField!
    
    
    var userName:String!
    var userPhone:String!
    var userEmail:String!
    var userImg:String!
    
    @IBOutlet weak var view_Phone: UIView!
    @IBOutlet weak var view_Email: UIView!
    @IBOutlet weak var view_Name: UIView!
    @IBOutlet weak var btnImg: UIButton!
    @IBOutlet weak var imgProfile: UIImageView!
    var userImg1:String!
    let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
    //    var  controller = AudioController.shared
    private var lastLoadFailed: Bool = false
    //    let playerService = AudioPlayerService.shared
    //    let playlistItemsService = PlaylistItemsService.shared
    
    
    
    let loading = indicator()
    @IBOutlet private weak var miniPlayerBookMarkButton : UIButton!
    @IBOutlet private weak var miniPlayerCrosskButton : UIButton!
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imgProfile.layer.borderWidth = 3
        self.imgProfile.layer.borderColor = UIColor(red: 79/255, green: 0, blue: 100/255, alpha: 1).cgColor
        if traitCollection.userInterfaceStyle == .dark {
            // Dark mode is active
            darkModeEnabled()
            print("Dark Mode is active")
        } else {
            // Light mode is active
            lightModeEnabled()
            print("Light Mode is active")
        }
        
        self.apiforgetProfile()
        //        controller.player.event.stateChange.addListener(self, handleAudioPlayerStateChange)
        //        handleAudioPlayerStateChange(data: controller.player.playerState)
        //
        //        self.playerService.delegate.add(delegate: self)
        //        txt_name.text = userName
        //        txt_email.text = userEmail
        //        txt_phone.text = userPhone
        //        if let i = userImg {
        //
        //            self.imgProfile.af.setImage(withURL: (URL(string:i) ?? URL(fileURLWithPath: "")))
        //
        //               }
        //        miniPlayerView.isHidden = true
        scrollView.delegate = self
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleTap))
        
        txt_phone.delegate = self
        
        imgProfile.layer.cornerRadius = imgProfile.frame.height/2
        imgProfile.clipsToBounds = true
        self.view_Phone.layer.borderWidth = 1
        self.view_Phone.layer.cornerRadius = 22.50
        self.view_Phone.layer.borderColor = UIColor(red:70/255, green:0/255, blue:100/255, alpha: 1).cgColor
        
        self.view_Email.layer.borderWidth = 1
        self.view_Email.layer.cornerRadius = 22.50
        self.view_Email.layer.borderColor = UIColor(red:70/255, green:0/255, blue:100/255, alpha: 1).cgColor
        
        self.view_Name.layer.borderWidth = 1
        self.view_Name.layer.cornerRadius = 22.50
        self.view_Name.layer.borderColor = UIColor(red:70/255, green:0/255, blue:100/255, alpha: 1).cgColor
        
        self.footerView.isHidden = true
        //        self.tableView.tableFooterView = UIView()
        //set tap handler to show detail on tap on footer view
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didPressShowDetail(_:)))
        self.footerView.addGestureRecognizer(tapRecognizer)
        footerView.isUserInteractionEnabled = true
        
        
        self.footerView.clipsToBounds = true
        self.footerView.layer.cornerRadius = 20
        self.footerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBookPlay), name: Notification.Name.AudiobookPlayer.bookPlayed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBookPause), name: Notification.Name.AudiobookPlayer.bookPaused, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBookPause), name: Notification.Name.AudiobookPlayer.bookEnd, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBookStop(_:)), name: Notification.Name.AudiobookPlayer.bookStopped, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.bookChange(_:)), name: Notification.Name.AudiobookPlayer.bookChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.bookReady(_:)), name: Notification.Name.AudiobookPlayer.bookReady, object: nil)
        
        //        if self.playerService.state == .playing{
        //
        //            miniPlayerView.isHidden = false
        //            self.miniPlayerButton.setImage(#imageLiteral(resourceName: "21.png"), for: .normal)
        //        }else if self.playerService.state == .paused{
        //            print("paused..............")
        //            self.miniPlayerButton.setImage(#imageLiteral(resourceName: "29.png"), for: .normal)
        //
        //        }else if self.playerService.state == .stopped{
        //
        //            print("stopped..............")
        //        }
        
        
        
        
        //        updateMetaData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if PlayerManager.shared.isPlaying {
            self.footerView.isHidden = false
        }
        guard let b = currentBok else{return}
        self.setupMiniPlayer(book: b)
    }
    
    @objc func removeMiniPlayer(_ sender:UIButton) {
        
        
    }
    
    @objc func bookMarkBtn_miniPlayer(_ sender:UIButton) {
        
        
    }
    
    @objc func play_pauseImgSet(_ notification:Notification){
       
    }
    /**
     * Set play or pause image on button
     */
    
    
    @objc func handleAudioInterruptions(_ notification:Notification){
        
      
    }
    
    
    @IBAction private func playPausePlayerButton(_ sender:UIButton) {
        //        if lastLoadFailed, let item = controller.player.currentItem {
        //            lastLoadFailed = false
        //
        //            try? controller.player.load(item: item, playWhenReady: true)
        //        }
        //        else {
        //            controller.player.togglePlaying()
        //        }
        
    }
    
    func apiforgetProfile() {
        
        let userid = UserDetail.shared.getUserId()
        
        // var params = [String: Any]()
        
        let jsonDict : [String:Any] = ["user_id": userid ?? ""]
        
        let loginURL = baseURL.baseURL + appEndPoints.GetUserByID
        
        print(loginURL, "API_URL")
        
        self.loading.showActivityIndicator(uiView: self.view)
        WebService.shared.servicePostWithFoamDataParameter(loginURL, jsonDict, withCompletion: { [self] (json, statusCode) in
            self.loading.hideActivityIndicator(uiView: self.view)
            let dict = "\(json)"
            var dictData : [String:Any]?
            if let data = dict.data(using: .utf8) {
                do {
                    dictData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                } catch {
                    print(error.localizedDescription)
                }
            }
            if (dictData!["success"] as! Bool) == true {
                
                if let resultData = dictData!["data"] as? [String:Any]{
                    print(resultData,"resultDatagetProfile")
                    if let i = resultData["image"] as? String  {
                        self.userImg1 = i
                        self.imgProfile.af.setImage(withURL: (URL(string:i) ?? URL(fileURLWithPath: "")))
                        
                    }
                    txt_name.text = resultData["name"] as? String
                    txt_email.text  = resultData["email"] as? String
                    txt_phone.text = resultData["phone"] as? String
                    
                    
                    //                    if let url = URL(string:(resultData["image"] as? String)!){
                    //                        imgProfile.image = UIImage(named: url)
                    //                      }
                    
                    
                    
                }
                
                else{
                    
                    
                }
                
            }
            //  hideHud()
        })
    }
    
    
    
    @IBAction private func tapMiniPlayerButton() {
        //  handleTap()
        //        guard let m = self.modalVC else { return }
        //        self.present(m, animated: true, completion: nil)
    }
    
    @objc func handleTap() {
        print ("Tap on miniPlayerView detected")
        
        //            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        //            let secondViewController = storyBoard.instantiateViewController(withIdentifier: "NowPlayingVC") as! NowPlayingVC
        //            self.present(secondViewController, animated:true, completion:nil)
        
        
        // self.setup()
        
    }
    
    
    
    
    @IBAction func btnResetPassword_Action(_ sender: Any) {
        
        let vc: ResetPasswordVC = self.storyboard?.instantiateViewController(withIdentifier: "ResetPasswordVC") as! ResetPasswordVC
        
        vc.delegate = self
        
        self.addChild(vc)
        vc.view.frame = self.view.frame
        self.view.addSubview(vc.view)
        self.view.bringSubviewToFront(vc.view)
        vc.didMove(toParent: self)
        
    }
    
    @IBAction func btn_SubmitAction(_ sender: Any) {
        guard validation() else {
            return }
        
        
        let imageData1 = self.imgProfile.image!.pngData()
        
        let userid = UserDetail.shared.getUserId()
        
        let jsonDict : [String:Any] = ["user_id" : "\(userid)","email" : txt_email.text!,"phone" : txt_phone.text!,"name" : txt_name.text!]
        
        print(jsonDict,"jsonDict")
        
        let loginURL = baseURL.baseURL + appEndPoints.profile_create //+appEndPoints.profile_create
        
        print(loginURL, "Api_URL")
        self.loading.showActivityIndicator(uiView: self.view)
        WebService.shared.uploadImageWithParameter(loginURL, imageData1, jsonDict, imageName: "image",withCompletion: {(json, statusCode) in
            self.loading.hideActivityIndicator(uiView: self.view)
            let dict = "\(json)"
            var dictData : [String:Any]?
            if let data = dict.data(using: .utf8) {
                do {
                    dictData = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                    
                    
                } catch {
                    print(error.localizedDescription)
                }
            }
            if dictData!["msg_type"] as? String == "true"{
                
                //self.showToast("Profile created successfully.")
                
                // DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [self] in
                
                let vc = self.storyboard?.instantiateViewController(withIdentifier: "TabBarVC") as! TabBarVC
                vc.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(vc, animated: true)
                //}
                // completionHandler("\(String(describing: dictData!["message"] as? String))", "")
            }  else    {
                let responseMessage = dictData!["msg"] as! String
                //self.showToast(responseMessage)
                AlertController.alert(title: "", message: responseMessage)
            }
            //            hideHud()
        })
        
        //        let vc = self.storyboard?.instantiateViewController(withIdentifier: "TabBarViewController") as! TabBarViewController
        //        vc.hidesBottomBarWhenPushed = true
        //        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func btnBack_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func btnSelectProfile_ImageAction(_ sender: Any) {
        
        let alert:UIAlertController=UIAlertController(title: "Choose Image", message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        let cameraAction = UIAlertAction(title: "Camera", style: UIAlertAction.Style.default) {
            UIAlertAction in
            self.openCamera(UIImagePickerController.SourceType.camera)
        }
        let gallaryAction = UIAlertAction(title: "Gallary", style: UIAlertAction.Style.default) {
            UIAlertAction in
            self.openCamera(UIImagePickerController.SourceType.photoLibrary)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
            UIAlertAction in
        }
        
        // Add the actions
        imagePicker.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
        alert.addAction(cameraAction)
        alert.addAction(gallaryAction)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    func openCamera(_ sourceType: UIImagePickerController.SourceType) {
        imagePicker.sourceType = sourceType
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    //MARK:UIImagePickerControllerDelegate
    
    internal func imagePickerController(_ picker: UIImagePickerController,
                                       didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //  imgProfile.image = info[UIImagePickerController.InfoKey.originalImage as? String] as? UIImage
        print(info)
        imagePicker.dismiss(animated: true, completion: nil)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        print(info["UIImagePickerControllerOriginalImage"] as? UIImage)
        imgProfile.image = info["UIImagePickerControllerOriginalImage"] as? UIImage
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("imagePickerController cancel")
    }
    func validateEmail(YourEMailAddress: String) -> Bool {
        let REGEX: String
        REGEX = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,3}"
        return NSPredicate(format: "SELF MATCHES %@", REGEX).evaluate(with: YourEMailAddress)
    }
    func validation() -> Bool {
        
        if txt_name.text?.count == 0 {
            self.popupAlert(title: "Error", message: "Name can't be empty.", actionTitles: ["Ok"], actions:[{action1 in}])
            return false
            
        } else if txt_email.text?.isNumeric == false {
            if  !validateEmail(YourEMailAddress: txt_email.text!){
                self.popupAlert(title: "Error", message: "Please enter valid email.", actionTitles: ["Ok"], actions:[{action1 in}])
                return false
            }
            
        }
        if txt_phone.text?.isNumeric == true || txt_phone.text!.count != 17 {
            if  !txt_phone.text!.isValidPhone(){
                self.popupAlert(title: "Error", message: "Please enter valid phone number.", actionTitles: ["Ok"], actions:[{action1 in}])
                return false
            }
            
        }
        
        return true
    }
    //mask example: `+X (XXX) XXX-XXXX`
    func format(with mask: String, phone: String) -> String {
        let numbers = phone.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        var result = ""
        var index = numbers.startIndex // numbers iterator
        
        // iterate over the mask characters until the iterator of numbers ends
        for ch in mask where index < numbers.endIndex {
            if ch == "X" {
                // mask requires a number in this place, so take the next one
                result.append(numbers[index])
                
                // move numbers iterator to the next index
                index = numbers.index(after: index)
                
            } else {
                result.append(ch) // just append a mask character
            }
        }
        return result
    }
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let text = txt_phone.text else { return false }
        let newString = (text as NSString).replacingCharacters(in: range, with: string)
        txt_phone.text = format(with: "+X (XXX) XXX-XXXX", phone: newString)
        return false
    }
    @IBAction func didPressPlay(_ sender: UIButton){
        PlayerManager.shared.playPause()
        self.setPlayImage()
    }
    @IBAction func miniplayerCrossBtn_Action(_ sender: UIButton){
        PlayerManager.shared.miniPlayerIsHidden = true
        self.footerView.isHidden = true
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
           
            tabBarController?.selectedIndex = 1
        }else{
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let playerVC = storyboard.instantiateViewController(withIdentifier: "PlayerViewController") as! PlayerViewController
            guard let b = currentBok else {return}
            playerVC.book = b
           
            tabBarController?.selectedIndex = 1
        }
        
      
    }
    
}

extension UpdateProfileVC: UIScrollViewDelegate {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        
        
        
        //--- Change Scroll View Indicator Color ---//
        if #available(iOS 13, *) {
            let verticalIndicatorView = (scrollView.subviews[(scrollView.subviews.count - 1)].subviews[0])
            let horizontalIndicatorView = (scrollView.subviews[(scrollView.subviews.count - 2)].subviews[0])
            
            //let colors = [UIColor(named: "#E54F4F")!.cgColor, UIColor(named: "##E61C1C")!.cgColor, UIColor(named: "#8E0202")!.cgColor]
            
            verticalIndicatorView.backgroundColor = UIColor.clear
            verticalIndicatorView.backgroundColor = UIColor(red: 79/255, green: 0/255, blue: 100/255, alpha: 1)
            //verticalIndicatorView.setGradient(colors: colors, angle: 90.0)
            
            horizontalIndicatorView.backgroundColor = UIColor.clear
            horizontalIndicatorView.backgroundColor = UIColor(red: 79/255, green: 0/255, blue: 100/255, alpha: 1)
            
        } else {
            
           // let colors = [UIColor(named: "#E54F4F")!.cgColor, UIColor(named: "##E61C1C")!.cgColor, UIColor(named: "#8E0202")!.cgColor]
            
            if let verticalIndicatorView: UIImageView = (scrollView.subviews[(scrollView.subviews.count - 1)] as? UIImageView) {
                verticalIndicatorView.backgroundColor = UIColor.clear
                verticalIndicatorView.backgroundColor = UIColor(red: 79/255, green: 0/255, blue: 100/255, alpha: 1)
            }

            if let horizontalIndicatorView: UIImageView = (scrollView.subviews[(scrollView.subviews.count - 2)] as? UIImageView) {
                horizontalIndicatorView.backgroundColor = UIColor.clear
                horizontalIndicatorView.backgroundColor = UIColor(red: 79/255, green: 0/255, blue: 100/255, alpha: 1)
            }
        }
   }
}


//extension UpdateProfileVC :AudioPlayerServiceDelegate  {
//    func errorOccurred(error: AudioStreaming.AudioPlayerError) {
//        print("startDisplayLink()")
//    }
//    
//    func metadataReceived(metadata: [String : String]) {
//        print("startDisplayLink()")
//    }
//    
//    func didStartPlaying() {
//        
//        print("startDisplayLink()")
//        
//    }
//    
//    func didStopPlaying() {
//        
//    }
//    func statusChanged(status: AudioStreaming.AudioPlayerState) {
//        switch status {
//        case .bufferring:
//            print("bufferring..........")
//        case .playing:
//            print("playing..............")
//            self.miniPlayerButton.setImage(#imageLiteral(resourceName: "21.png"), for: .normal)
//            miniPlayerView.isHidden = false
//        case .paused:
//            print("paused..............")
//            self.miniPlayerButton.setImage(#imageLiteral(resourceName: "29.png"), for: .normal)
//        case .stopped:
//            print("stopped..............")
//        default:
//            break
//        }
//        
//    }
//    
//}
//extension UpdateProfileVC {
//    func handleAudioPlayerStateChange(data: AudioPlayer.StateChangeEventData) {
//        print("state=\(data)")
//        DispatchQueue.main.async {
//            self.updateMetaData()
//            self.setPlayButtonState(forAudioPlayerState: data)
//        }
//    }
//    func setPlayButtonState(forAudioPlayerState state: AudioPlayerState) {
//        if state == .playing {
//            miniPlayerView.isHidden = false
//            self.miniPlayerButton.setImage(#imageLiteral(resourceName: "21.png"), for: .normal)
//        }else{
//
//            self.miniPlayerButton.setImage(#imageLiteral(resourceName: "29.png"), for: .normal)
//        }
//
//    }
//    func updateMetaData() {
//        self.txt_mini_chapter.text = controller.player.currentItem?.getTitle() ?? ""
//
//        controller.player.currentItem?.getArtwork({ img in
//            self.img_mini_chapter.image = img
//        })
//        self.txt_mini_album.text = controller.player.currentItem?.getAlbumTitle() ?? ""
//
//
//    }
//}
extension UpdateProfileVC:TapOnOptions{
    func tapped(conditionValue: Int) {
        self.presentedViewController?.dismiss(animated: true)
        switch conditionValue {
        case 0:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "GetProfileVC") as! GetProfileVC
            self.navigationController?.pushViewController(vc, animated: true)
        case 1:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "SettingVC") as! SettingVC
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
extension UpdateProfileVC {
    @objc func bookEnd(_ notification:Notification) {
        self.setPlayImage()
    }
    @objc private func onBookPause() {
        self.footerPlayButton.setImage(self.miniPlayImage, for: UIControl.State())
       
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
        let title = book.title ?? "Unknown"
         let author = book.author ?? "Unknown"
        self.footerImageView.image = book.artwork
        self.footerTitleLabel.text = title + " - " + author
         
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
//MARK: - Dark/Light mode logic
extension UpdateProfileVC {
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
        txt_name.attributedPlaceholder = NSAttributedString(string:"Enter Your Name", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 40/255, green: 0, blue: 71/255, alpha: 1)])
        txt_email.attributedPlaceholder = NSAttributedString(string:"Enter Your Email", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 40/255, green: 0, blue: 71/255, alpha: 1)])
        txt_phone.attributedPlaceholder = NSAttributedString(string:"Enter Your Phone Number", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 40/255, green: 0, blue: 71/255, alpha: 1)])
    }
    private func darkModeEnabled() {
        txt_name.attributedPlaceholder = NSAttributedString(string:"Enter Your Name", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        txt_email.attributedPlaceholder = NSAttributedString(string:"Enter Your Email", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        txt_phone.attributedPlaceholder = NSAttributedString(string:"Enter Your Phone Number", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    }
}
