//
//  GetProfileVC.swift
//  SpeedListners
//
//  Created by ravi on 9/08/22.
//

import UIKit
import AlamofireImage
import MediaPlayer

class GetProfileVC: UIViewController {
    
    @IBOutlet weak var txt_Phone: UITextField!
    @IBOutlet weak var txt_Email: UITextField!
    @IBOutlet weak var txt_Name: UITextField!
    @IBOutlet weak var view_Phone: UIView!
    @IBOutlet weak var view_Email: UIView!
    @IBOutlet weak var view_Name: UIView!
    @IBOutlet weak var btnImg: UIButton!
    @IBOutlet weak var imgProfile: UIImageView!
    var getProfileArr = [ModelClass]()
    @IBOutlet weak var scrollView: UIScrollView!
    //for mini player
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerView1: UIView!
    @IBOutlet weak var footerImageView: UIImageView!
    @IBOutlet weak var footerTitleLabel: UILabel!
    @IBOutlet weak var footerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var footerPlayButton: UIButton!
    let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
    //keep in memory images to toggle play/pause
    let miniPlayImage = UIImage(named: "29")
    let miniPauseButton = UIImage(named: "21")
    
    @IBOutlet private weak var miniPlayerBookMarkButton : UIButton!
    @IBOutlet private weak var miniPlayerCrosskButton : UIButton!
    
    var userName1:String!
    var userPhone1:String!
    var userEmail1:String!
    var userImg1:String!
    let loading = indicator()
    
    private var lastLoadFailed: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        if traitCollection.userInterfaceStyle == .dark {
            // Dark mode is active
            darkModeEnabled()
            print("Dark Mode is active")
        } else {
            // Light mode is active
            lightModeEnabled()
            print("Light Mode is active")
        }
        self.imgProfile.layer.borderWidth = 3
        self.imgProfile.layer.borderColor = UIColor(red: 79/255, green: 0, blue: 100/255, alpha: 1).cgColor
        
        scrollView.delegate = self
        _ = UISwipeGestureRecognizer(target: self, action: #selector(handleTap))
        
        //        self.playerService.delegate.add(delegate: self)
        imgProfile.layer.cornerRadius = imgProfile.frame.height/2
        imgProfile.clipsToBounds = true
        //        miniPlayerView.isHidden = true
        //        controller.player.event.stateChange.addListener(self, handleAudioPlayerStateChange)
        //        handleAudioPlayerStateChange(data: controller.player.playerState)
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
        
        
        self.miniPlayerCrosskButton.addTarget(self, action: #selector(removeMiniPlayer(_:)), for: .touchUpInside)
        
        self.miniPlayerBookMarkButton.addTarget(self, action: #selector(bookMarkBtn_miniPlayer(_:)), for: .touchUpInside)
        self.apiforgetProfile()
        
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if PlayerManager.shared.isPlaying {
            self.footerView.isHidden = false
        }
        guard let b = currentBok else{return}
        self.setupMiniPlayer(book: b)
    }
    
    //Playback may be interrupted by calls. Handle pause
    @objc func play_pauseImgSet(_ notification:Notification){
       
    }
    
    
    @objc func handleAudioInterruptions(_ notification:Notification){
        
       
    }
    
    @objc func removeMiniPlayer(_ sender:UIButton) {
        
        
    }
    @objc func bookMarkBtn_miniPlayer(_ sender:UIButton) {
        
        
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
        
        let jsonDict : [String:Any] = ["user_id": userid ]
        
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
                    self.txt_Name.text = resultData["name"] as? String
                    self.txt_Email.text  = resultData["email"] as? String
                    self.txt_Phone.text = resultData["phone"] as? String
                    
                    self.userName1 = resultData["name"] as? String
                    self.userEmail1  = resultData["email"] as? String
                    self.userPhone1 = resultData["phone"] as? String
                    
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
        //
        //            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        //            let secondViewController = storyBoard.instantiateViewController(withIdentifier: "NowPlayingVC") as! NowPlayingVC
        //            self.present(secondViewController, animated:true, completion:nil)
        
        
        // self.setup()
        
    }
    @IBAction func btnSubmit_Action(_ sender: Any) {
        
    }
    @IBAction func btnUpdateProfile_Action(_ sender: Any) {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "UpdateProfileVC") as! UpdateProfileVC
        vc.userName = userName1
        vc.userEmail = userEmail1
        vc.userPhone = userPhone1
        vc.userImg = userImg1
        self.navigationController?.pushViewController(vc, animated: true)
        
        
    }
    @IBAction func btnBack_Action(_ sender: UIButton){
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func btnSelectProfile_ImageAction(_ sender: Any) {
        
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
extension GetProfileVC: UIScrollViewDelegate {
    
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

extension GetProfileVC:TapOnOptions{
    func tapped(conditionValue: Int) {
        self.presentedViewController?.dismiss(animated: true)
        switch conditionValue {
        case 0:break
        case 1:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "SettingVC") as! SettingVC
           // self.hidesBottomBarWhenPushed = true
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
extension GetProfileVC {
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
extension GetProfileVC {
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
        txt_Name.attributedPlaceholder = NSAttributedString(string:"Enter Your Name", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 40/255, green: 0, blue: 71/255, alpha: 1)])
        txt_Email.attributedPlaceholder = NSAttributedString(string:"Enter Your Email", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 40/255, green: 0, blue: 71/255, alpha: 1)])
        txt_Phone.attributedPlaceholder = NSAttributedString(string:"Enter Your Phone Number", attributes: [NSAttributedString.Key.foregroundColor: UIColor(red: 40/255, green: 0, blue: 71/255, alpha: 1)])
    }
    private func darkModeEnabled() {
        txt_Name.attributedPlaceholder = NSAttributedString(string:"Enter Your Name", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        txt_Email.attributedPlaceholder = NSAttributedString(string:"Enter Your Email", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
        txt_Phone.attributedPlaceholder = NSAttributedString(string:"Enter Your Phone Number", attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])
    }
}

