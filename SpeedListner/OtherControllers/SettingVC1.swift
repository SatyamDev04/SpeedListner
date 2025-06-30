//
//  SettingVC1.swift
//  SpeedListners
//
//  Created by ravi on 8/09/22.
//

import UIKit
import Movin

class SettingVC1: UIViewController,UITableViewDelegate,UITableViewDataSource {
   
    internal var modalVC: UIViewController?
    private var movin: Movin?
    private var isPresented: Bool = false
    
        @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var miniPlayerView: UIView!
    @IBOutlet private weak var miniPlayerButton : UIButton!

    @IBOutlet weak var lblLeadingConstraints: NSLayoutConstraint!
    @IBOutlet weak var tblV: UITableView!
    
    
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
    
    var imgArr = ["bxs_user-1x","bxs_contact-3x","eos-icons_1x","flat-color-1x","wpf_faq-1x","carbon_1x","fluent_person-1x","fluent_delete-1x","ri_logout-box-r-line-1x","ri_logout-box-r-line-1x"]

    var settingArr = ["User profile",
    "Contact us",
    "Privacy Policy",
    "About us",
    "FAQ",
    "Terms and Condition",
    "feedback",
    "Delete Account",
    "Logout","Your app version is 1.0"]
    
    var viewTranslation = CGPoint(x: 0, y: 0)
    
    @IBOutlet weak var view_subscription: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
       
        
      //  miniPlayerView.isUserInteractionEnabled = true
           // let tapGesture = UITapGestureRecognizer(target: self,
              //  action: #selector(handleTap))
      //  miniPlayerView.addGestureRecognizer(tapGesture)
        
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleTap))
        miniPlayerView.addGestureRecognizer(swipeGesture)
    
        view_subscription.layer.shadowColor = UIColor.black.cgColor
        view_subscription.layer.shadowOpacity = 0.5
        
        self.footerView.isHidden = true
//        self.tableView.tableFooterView = UIView()
        //set tap handler to show detail on tap on footer view
//        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.didPressShowDetail(_:)))
//        self.footerView.addGestureRecognizer(tapRecognizer)
        footerView.isUserInteractionEnabled = true
        
        self.footerHeightConstraint.constant = 0
        self.footerView.clipsToBounds = true
        self.footerView.layer.cornerRadius = 20
        self.footerView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        NotificationCenter.default.addObserver(self, selector: #selector(self.play_pauseImgSet(_:)), name: Notification.Name.AudiobookPlayer.play_pause, object: nil)
        
    }
    
    @objc func play_pauseImgSet(_ notification:Notification){
      
        
    }
    /**
     * Set play or pause image on button
     */
    func setPlayImage(){
      
    }
    
    @objc func handleAudioInterruptions(_ notification:Notification){
      
    }

    @objc func handleTap() {
        print ("Tap on miniPlayerView detected")
        
//        let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
//        let secondViewController = storyBoard.instantiateViewController(withIdentifier: "NowPlayingVC") as! NowPlayingVC
//        self.present(secondViewController, animated:true, completion:nil)

        
    self.setup()
        
    }
//    override var preferredStatusBarStyle: UIStatusBarStyle {
//        if self.isPresented {
//            return .lightContent
//        }
//        return .default
//    }
//
//    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
//        return .fade
//    }
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//        print("TopViewController - viewWillAppear")
//    }
//
//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
//        print("SettingVC1 - viewDidAppear")
////        self.setup()
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        print("SettingVC1 - viewWillDisappear")
//    }
//
//    override func viewDidDisappear(_ animated: Bool) {
//        super.viewDidDisappear(animated)
//        print("SettingVC1 - viewDidDisappear")
//    }
    
    private func setup() {
        if self.movin != nil { return }
        
        if #available(iOS 11.0, *) {
            self.movin = Movin(1.0, TimingCurve(curve: .easeInOut, dampingRatio: 0.8))
        } else {
            self.movin = Movin(1.0)
        }
        
        let modal = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PlayerViewController") as! PlayerViewController
        modal.view.layoutIfNeeded()
        
        let miniPlayerOrigin = self.miniPlayerView.frame.origin
       // let miniImageFrame = self.imageLayerView.frame
        //let originImageFrame = modal.imageView.frame
        let endModalOrigin = CGPoint(x: 0, y: 55)
        
        self.movin!.addAnimations([
            self.containerView.mvn.cornerRadius.from(0.0).to(10.0),
            self.containerView.mvn.alpha.from(1.0).to(0.6),
            self.containerView.mvn.transform.from(CGAffineTransform(scaleX: 1.0, y: 1.0)).to(CGAffineTransform(scaleX: 0.9, y: 0.9)),
            self.tabBarController!.tabBar.mvn.point.to(CGPoint(x: 0.0, y: self.view.frame.size.height)),
            modal.view.mvn.cornerRadius.from(0.0).to(10.0),
            //modal.imageView.mvn.frame.from(miniImageFrame).to(originImageFrame),
           // modal.imageLayerView.mvn.frame.from(miniImageFrame).to(originImageFrame),
            modal.view.mvn.point.from(miniPlayerOrigin).to(endModalOrigin),
            //modal.backgroundView.mvn.alpha.from(0.0).to(1.0),
           // modal.nameLabel.mvn.alpha.from(1.0).to(0.0),
            //modal.closeButton.mvn.alpha.from(0.0).to(1.0),
            ])
        
        let presentGesture = GestureAnimating(self.miniPlayerView, .top, self.view.frame.size)
        presentGesture.panCompletionThresholdRatio = 0.4
        let dismissGesture = GestureAnimating(modal.view, .bottom, modal.view.frame.size)
        dismissGesture.panCompletionThresholdRatio = 0.25
        dismissGesture.smoothness = 0.5
        
        let transition = Transition(self.movin!, self.tabBarController!, modal, GestureTransitioning(.present, presentGesture, dismissGesture))
        transition.customContainerViewSetupHandler = { [unowned self] type, containerView in
            if type.isPresenting {
                self.miniPlayerView.isHidden = true
                containerView.addSubview(modal.view)
                containerView.addSubview(self.tabBarController!.tabBar)
                modal.view.layoutIfNeeded()
                
                self.isPresented = true
                self.setNeedsStatusBarAppearanceUpdate()
                
                self.tabBarController?.beginAppearanceTransition(false, animated: false)
                modal.beginAppearanceTransition(true, animated: false)
            } else {
                self.tabBarController?.beginAppearanceTransition(true, animated: false)
                modal.beginAppearanceTransition(false, animated: false)
            }
        }
        transition.customContainerViewCompletionHandler = { [unowned self] type, didComplete, containerView in
            self.tabBarController?.endAppearanceTransition()
            modal.endAppearanceTransition()
            
            if type.isDismissing {
                if didComplete {
                    print("complete dismiss")
                    modal.view.removeFromSuperview()
                    self.tabBarController?.tabBar.removeFromSuperview()
                    self.tabBarController?.view.addSubview(self.tabBarController!.tabBar)
                    
                    self.miniPlayerView.isHidden = false
                    self.movin = nil
                    self.modalVC = nil
                    self.isPresented = false
                    self.setNeedsStatusBarAppearanceUpdate()
                    
                    self.setup()
                } else {
                    print("cancel dismiss")
                }
            } else {
                if didComplete {
                    print("complete present")
                } else {
                    print("cancel present")
                    modal.view.removeFromSuperview()
                    self.tabBarController?.tabBar.removeFromSuperview()
                    self.tabBarController?.view.addSubview(self.tabBarController!.tabBar)
                    
                    self.miniPlayerView.isHidden = false
                    self.isPresented = false
                    self.setNeedsStatusBarAppearanceUpdate()
                }
            }
        }
        
        self.modalVC = modal
        modal.modalPresentationStyle = .overCurrentContext
        modal.transitioningDelegate = self.movin!.configureCustomTransition(transition)
    }

    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tblV.dequeueReusableCell(withIdentifier: "SettingCell", for: indexPath) as! SettingCell
        cell.lbl_name.text = settingArr[indexPath.row]
        cell.img.image = UIImage(named: imgArr[indexPath.row])
        self.tblV.isScrollEnabled = false
        
        if indexPath.row == 9 {
            cell.img.isHidden = true
            //cell.lblLeadingContraints.constant = -15
            
            cell.lbl_name.text = settingArr[indexPath.row]
        }
        
        return cell
    }

    @IBAction func btnBack_Action(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction private func tapMiniPlayerButton() {
       // setup()
       handleTap()
//        guard let m = self.modalVC else { return }
//        self.present(m, animated: true, completion: nil)
    }
    
    @IBAction func cancelSubscription_Action(_ sender: Any) {
        
        let vc: CancelSubscriptionVC = self.storyboard?.instantiateViewController(withIdentifier: "CancelSubscriptionVC") as! CancelSubscriptionVC
        
      // vc.delegateforfeedbackPopup = self
       
        self.addChild(vc)
        vc.view.frame = self.view.frame
        self.view.addSubview(vc.view)
        self.view.bringSubviewToFront(vc.view)
        vc.didMove(toParent: self)
        
//        let vc = self.storyboard?.instantiateViewController(withIdentifier: "CancelSubscriptionVC") as! CancelSubscriptionVC
//        self.navigationController?.pushViewController(vc, animated: true)
        
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tblV.cellForRow(at: indexPath)
        var count = indexPath.row
        switch count {
        case 0:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "UpdateProfileVC") as! UpdateProfileVC
            self.navigationController?.pushViewController(vc, animated: true)
           case 1:
            break
           case 2:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "PrivacyVC") as! PrivacyVC
            self.navigationController?.pushViewController(vc, animated: true)
        case 3:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "AboutVC") as! AboutVC
            self.navigationController?.pushViewController(vc, animated: true)
        case 4:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "FAQVC") as! FAQVC
            self.navigationController?.pushViewController(vc, animated: true)
        case 5:
         let vc = self.storyboard?.instantiateViewController(withIdentifier: "TermsConditionVC") as! TermsConditionVC
         self.navigationController?.pushViewController(vc, animated: true)
        case 6:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "FeedbackVC") as! FeedbackVC
            self.navigationController?.pushViewController(vc, animated: true)
        case 7:
         let vc = self.storyboard?.instantiateViewController(withIdentifier: "DeleteAcountVC") as! DeleteAcountVC
         self.navigationController?.pushViewController(vc, animated: true)
        case 8:
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "LogoutPop1VC") as! LogoutPop1VC
            self.navigationController?.pushViewController(vc, animated: true)
        
           default:
             break
          }
    }
    

}


final class LineView: UIView {
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        let topLine = UIBezierPath(rect: CGRect(x: 0, y: 0, width: self.frame.size.width, height: 0.2))
        UIColor.gray.setStroke()
        topLine.lineWidth = 0.2
        topLine.stroke()
    }
}
