//
//  SettingVC.swift
//  SpeedListners
//
//  Created by ravi on 22/08/22.
//

import UIKit
import DropDown
import MediaPlayer
//import AudioStreaming



class SettingVC: UIViewController, Afterpay {
    
    
    let topMenu = DropDown()
    lazy var dropDowns: [DropDown] = {
        return [
            self.topMenu,
//            self.DownMenu
        ]
    }()
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var view_subscription: UIView!
    @IBOutlet private weak var miniPlayerBookMarkButton : UIButton!
    @IBOutlet private weak var miniPlayerCrosskButton : UIButton!
    @IBOutlet private weak var buySubscription : UIButton!
    //for mini player
    @IBOutlet weak var footerView: UIView!
    @IBOutlet weak var footerView1: UIView!
    @IBOutlet weak var footerImageView: UIImageView!
    @IBOutlet weak var footerTitleLabel: UILabel!
    @IBOutlet weak var subscriptionInfoLabel: UILabel!
    @IBOutlet weak var visuallyImpairedLabel: UILabel!
    @IBOutlet weak var darkModeLbl: UILabel!
    @IBOutlet weak var footerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var footerPlayButton: UIButton!
    @IBOutlet weak var CollV:UICollectionView!
    //keep in memory images to toggle play/pause
    let miniPlayImage = UIImage(named: "29")
    let miniPauseButton = UIImage(named: "21")
    var planDs:NSDictionary?
    var clickBool:Bool = false
    let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
    private var lastLoadFailed: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        self.view_subscription.layer.shadowColor = UIColor.black.cgColor
        self.view_subscription.layer.shadowOpacity = 0.1
        self.tabBarController?.delegate = self
        
        self.miniPlayerCrosskButton.addTarget(self, action: #selector(removeMiniPlayer(_:)), for: .touchUpInside)
        self.miniPlayerBookMarkButton.addTarget(self, action: #selector(bookMarkBtn_miniPlayer(_:)), for: .touchUpInside)
        
   
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
        
        self.CollV.delegate = self
        self.CollV.dataSource = self
        self.CollV.register(UINib(nibName: "SubsPlanCell", bundle: nil), forCellWithReuseIdentifier: "SubsPlanCell")
        if traitCollection.userInterfaceStyle == .dark {
            // Dark mode is active
            darkModeEnabled()
            print("Dark Mode is active")
        } else {
            // Light mode is active
            lightModeEnabled()
            print("Light Mode is active")
        }


    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let d = UserDefaults.standard.object(forKey: "desable") as? Bool{
            if d == true{
             
                visuallyImpairedLabel.text = "Visually Impaired Mode -   ON"
                
            }else{
               
                visuallyImpairedLabel.text = "Visually Impaired Mode -   OFF"
            }
        }else{
          
            visuallyImpairedLabel.text = "Visually Impaired Mode -   OFF"
        }
//        if let d = UserDefaults.standard.object(forKey: "darkmode") as? Bool{
//            if d == true{
//            
//                darkModeLbl.text = "Dark Mode -  ON"
//            }else{
//               
//                darkModeLbl.text = "Dark Mode -  OFF"
//            }
//        }else{
//          
//            darkModeLbl.text = "Dark Mode -  OFF"
//        }
        if PlayerManager.shared.isPlaying {
            self.footerView.isHidden = false
        }
        guard let b = currentBok else{return}
        self.setupMiniPlayer(book: b)
        self.planData()
       
    }
    
    
    @IBAction private func playPausePlayerButton(_ sender:UIButton) {
      
        }
    
    @objc func removeMiniPlayer(_ sender:UIButton) {
        
        
    }
    @objc func bookMarkBtn_miniPlayer(_ sender:UIButton) {
        
        
    }
    @objc func play_pauseImgSet(_ notification:Notification){
    
    }
    /*
      Set play or pause image on button
     */
    
    
    @objc func handleAudioInterruptions(_ notification:Notification){
       
    }
    @IBAction func didPressPlay(_ sender: UIButton){
        PlayerManager.shared.playPause()
        self.setPlayImage()
        
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
    @IBAction func miniplayerCrossBtn_Action(_ sender: UIButton){
        PlayerManager.shared.miniPlayerIsHidden = true
       // self.footerView.isHidden = true
    }
    
    @objc func handleTap() {
        print ("Tap on miniPlayerView detected")
        
        
        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
        let secondViewController = storyBoard.instantiateViewController(withIdentifier: "PlayerViewController") as! PlayerViewController
        self.present(secondViewController, animated:true, completion:nil)

        
 
        
    }
    func scrollViewDidScroll(scrollView: UIScrollView){
  
        let horizontalIndicator: UIImageView = (scrollView.subviews[(scrollView.subviews.count - 2)] as! UIImageView)
        horizontalIndicator.image = nil
        horizontalIndicator.backgroundColor = UIColor(red: 211/255.0, green: 138/255.0, blue: 252/255.0, alpha: 1)


    }
    
    @IBAction func btnTermCondion_Action(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "TermsConditionVC") as! TermsConditionVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction private func tapMiniPlayerButton() {
       // setup()
       handleTap()
//        guard let m = self.modalVC else { return }
//        self.present(m, animated: true, completion: nil)
    }
    
    @IBAction func btnLogout_Action(_ sender: Any) {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "LogoutPop1VC") as! LogoutPop1VC
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    @IBAction func btnDesable_Action(_ sender: Any) {
        self.clickBool = true
        if let d = UserDefaults.standard.object(forKey: "desable") as? Bool{
            if d == true{
                UserDefaults.standard.set(false, forKey: "desable")
                visuallyImpairedLabel.text = "Visually Impaired Mode -   OFF"
            }else{
                UserDefaults.standard.set(true, forKey: "desable")
                visuallyImpairedLabel.text = "Visually Impaired Mode -   ON"
            }
        }else{
            UserDefaults.standard.set(true, forKey: "desable")
            visuallyImpairedLabel.text = "Visually Impaired Mode -   ON"
        }
        
        
    }
    @IBAction func btnDarkMode_Action(_ sender: Any) {
        if darkModeLbl.text == "Dark Mode - ON" {
            // Turn off dark mode
            darkModeLbl.text = "Dark Mode - OFF"
            if #available(iOS 13, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.windows.forEach { window in
                        window.overrideUserInterfaceStyle = .light
                    }
                }
            }
            UserDefaults.standard.set(false, forKey: "darkmode")
            print("Dark Mode is OFF")
        } else {
            // Turn on dark mode
            darkModeLbl.text = "Dark Mode - ON"
            if #available(iOS 13, *) {
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    windowScene.windows.forEach { window in
                        window.overrideUserInterfaceStyle = .dark
                    }
                }
            }
            UserDefaults.standard.set(true, forKey: "darkmode")
            print("Dark Mode is ON")
        }
        
    }
    
    @IBAction func btnAboutus_Aciton(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "AboutVC") as! AboutVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func btnFAQ_Action(_ sender: Any) {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "FAQVC") as! FAQVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func btnPrivacy_Action(_ sender: Any) {
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "PrivacyVC") as! PrivacyVC
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    @IBAction func btnContactus_Action(_ sender: Any) {
        
    }
    
    @IBAction func btnUpdateProfile_Action(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "UpdateProfileVC") as! UpdateProfileVC
        self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func btnFeedback_Action(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "FeedbackVC") as! FeedbackVC
        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    @IBAction func cancelSubscription_Action(_ sender: Any) {
        if buySubscription.currentTitle == "Buy Subscription" {
            self.buyplan()
        }else{
            let vc: CancelSubscriptionVC = self.storyboard?.instantiateViewController(withIdentifier: "CancelSubscriptionVC") as! CancelSubscriptionVC
            
            // vc.delegateforfeedbackPopup = self
            vc.cancelSub = {
                self.cancelPlan()
            }
            self.addChild(vc)
            vc.view.frame = self.view.frame
            self.view.addSubview(vc.view)
            self.view.bringSubviewToFront(vc.view)
            vc.didMove(toParent: self)
        }
//        let vc = self.storyboard?.instantiateViewController(withIdentifier: "CancelSubscriptionVC") as! CancelSubscriptionVC
//        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    @IBAction func btnback_Action(_ sender: UIButton) {
        if clickBool {
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "TabBarVC") as! TabBarVC
           self.hidesBottomBarWhenPushed = true
        self.navigationController!.pushViewController(vc, animated: false)
        }else{
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @IBAction func btnDeleteAccount_Action(_ sender: Any) {
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "DeleteAcountVC") as! DeleteAcountVC
                self.navigationController?.pushViewController(vc, animated: true)
    }
    @IBAction func btnMenu_Aciton(_ sender: UIButton) {
        self.topMenu.anchorView = sender
        self.topMenu.bottomOffset = CGPoint(x: -100, y: sender.bounds.height + 8)
        self.topMenu.textColor = .black
        self.topMenu.cornerRadius = 5.0
        
        let backgroundImage = UIImageView(frame: UIScreen.main.bounds)
        backgroundImage.image = UIImage(named: "1")
        
        backgroundImage.contentMode =  UIView.ContentMode.topLeft
        self.topMenu.insertSubview(backgroundImage, at: 0)

//        self.topMenu.borderWidth = 1
//        self.topMenu.borderColor = #colorLiteral(red: 0.3842016757, green: 0.2161925137, blue: 0.7387148142, alpha: 1)
        self.topMenu.separatorColor = .clear
        self.topMenu.selectionBackgroundColor = .clear
        self.topMenu.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        self.topMenu.dataSource.removeAll()
        
       self.topMenu.dataSource.append(contentsOf: ["Profile","Settings"])
        
        let imgArr = ["Vector","Settings"]
        
        topMenu.cellNib = UINib(nibName: "DropDownCell", bundle: nil)
        topMenu.customCellConfiguration = { index, title, cell in
            
            guard let cell = cell as? MyCell1 else {
                return
            }
            cell.img1.image = UIImage(named: imgArr[index])
            // UIImage(systemName: imagesArr[index])
           // cell.lbltitle.text = aArr[index]
        }
        topMenu.selectionAction = { [unowned self] (index, item) in
            if index == 0 {
                
//                let vc = self.storyboard?.instantiateViewController(withIdentifier: "GetProfileVC") as! GetProfileVC
//                self.navigationController?.pushViewController(vc, animated: true)
      
            }else{
//                let vc = self.storyboard?.instantiateViewController(withIdentifier: "SignUpVC") as! SignUpVC
//                self.navigationController?.pushViewController(vc, animated: true)
            }
//
        }
       
        self.topMenu.show()
       
    }
    
}


extension SettingVC:UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SubsPlanCell", for: indexPath) as! SubsPlanCell
      
        let g = self.planDs
        cell.offerPrice_lbl.text = "$\( g?["price"] ?? "")"
        cell.actualPrice_lbl.text = "$\( g?["sub_plan"] ?? "")"
        return cell
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.size.height)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
}
extension SettingVC {
    func planData(){
        
        WebService.shared.getService("https://speedlistener.yesitlabs.co/api/plan_list", andParameter: nil) { Json, respons in
            
            if respons == 200 {
                guard let dict = Json.dictionaryObject else {return}
                if let status = dict["success"] as? Bool,status == true,let msg = dict["message"] as? String,let plans = dict["data"] as? NSDictionary{
                    
                    self.planDs = plans
                    self.subscribedPlanDetail()
                    DispatchQueue.main.async {
                        self.CollV.reloadData()
                    }
                 
            
                }
            }
            
            
        }
    }
    func buyplan()  {
        
        //self.loading.showActivityLoading(uiView: self.view)

         var para  = [String:Any]()
         para["user_id"] = UserDetail.shared.getUserId()
         para["sub_id"] = self.planDs?["sub_id"] ?? ""
         para["price"] = self.planDs?["price"] ?? ""
         para["sub_plan"] = self.planDs?["sub_plan"] ?? ""
         //self.subsPriceLbl.text ?? ""

        WebService.shared.postService("https://speedlistener.yesitlabs.co/api/payment", andParameter: para, withCompletion: { json, response in
            
             guard let dict = json.dictionaryObject else{ return }
             if let status = dict["code"] as? Int, status == 200,let url = dict["url"] as? String {
              
                 let vc = self.storyboard?.instantiateViewController(withIdentifier: "PLRBsdkVC") as!  PLRBsdkVC
                 vc.url = url
                 vc.isModalInPresentation = true
                 vc.delegate = self
                 self.present(vc, animated: true)
             }else {
             
             }
         })
     }
    
    func cancelPlan() {
        
        //self.loading.showActivityLoading(uiView: self.view)

         var para  = [String:Any]()
         para["user_id"] = UserDetail.shared.getUserId()
         
       
        WebService.shared.postService("https://speedlistener.yesitlabs.co/api/user_subscription_cancel", andParameter: para, withCompletion: { json, response in
            
             guard let dict = json.dictionaryObject else{ return }
             if let status = dict["success"] as? Bool, status == true{
                 self.subscribedPlanDetail()
                
             }else {
                 self.subscribedPlanDetail()
             }
         })
     }
    
    func subscribedPlanDetail(){
        
        //self.loading.showActivityLoading(uiView: self.view)

         var para  = [String:Any]()
        
        para["user_id"] = UserDetail.shared.getUserId()
        

        WebService.shared.postService("https://speedlistener.yesitlabs.co/api/user_subscription_details", andParameter: para, withCompletion: { json, response in
            
             guard let dict = json.dictionaryObject else{ return }
             if let status = dict["success"] as? Bool, status == true,let data = dict["data"] as? NSArray,let dic = data[0] as? NSDictionary {
                 if let d =  dic["plan_expiry_check"] as? Int,d == 0,let plan_expiry_date = dic["plan_expiry_date"] as? String {
                     self.buySubscription.setTitle("Cancel Subscription", for: .normal)
                     let startDate = plan_expiry_date
                     let dateFormatter = DateFormatter()
                     dateFormatter.dateFormat = "yyyy-MM-dd"
                     let formatedStartDate = dateFormatter.date(from: startDate)
                     let currentDate = Date()
                     let components = Set<Calendar.Component>([.day])
                     let differenceOfDate = Calendar.current.dateComponents(components, from: currentDate, to: formatedStartDate!)

                     print (differenceOfDate.day)
                     
                     self.subscriptionInfoLabel.text = "Your Current Subscription Is Active You Have \(differenceOfDate.day ?? 0) Days Left On Your Current Subscription Plan."
                     
                 }else{
                     self.subscriptionInfoLabel.text = "Please Subscribe For Enjoy All Features"
                     self.buySubscription.setTitle("Buy Subscription", for: .normal)
                 }
                
             }else {
                 self.subscriptionInfoLabel.text = "Please Subscribe For Enjoy All Features"
                 self.buySubscription.setTitle("Buy Subscription", for: .normal)

             }
         })
     }
    
    func afterPayData(paymentDetails: [String : Any]) {
        self.showToast("Subscription Started Successfully")
        self.subscribedPlanDetail()
    }
    
    
}

struct PlansModel {
    var sub_id, price, sub_plan:String
}
extension SettingVC:TapOnOptions{
    func tapped(conditionValue: Int) {
        self.presentedViewController?.dismiss(animated: true)
        switch conditionValue {
        case 0:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "GetProfileVC") as! GetProfileVC
            self.navigationController?.pushViewController(vc, animated: true)

        case 1:break
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
extension SettingVC {
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
extension SettingVC :UITabBarControllerDelegate{
    func tabBarController(_ tabBarController: UITabBarController, shouldSelect viewController: UIViewController) -> Bool {
       
        if self.clickBool {
            if tabBarController.selectedIndex == 0{
                self.btnback_Action(UIButton())
            }
            return false
        } else {
           
            return true
        }
    }
    
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        switch traitCollection.userInterfaceStyle {
        case .dark: darkModeEnabled()
        case .light: fallthrough
        case .unspecified: fallthrough
        default: lightModeEnabled()   // Switch to light mode colors, etc.
        }
    }
    private func lightModeEnabled() {
        darkModeLbl.text = "Dark Mode - OFF"
        //        self.topMenu.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
    }
    private func darkModeEnabled() {
        darkModeLbl.text = "Dark Mode - ON"
        //        self.topMenu.backgroundColor = #colorLiteral(red: 0.1098039216, green: 0.1098039216, blue: 0.1176470588, alpha: 1)
    }
}
