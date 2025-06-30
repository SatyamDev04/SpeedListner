//
//  PlayerViewController.swift
//  SpeedListner
//
//  Created by satyam on 8/6/23.
//
protocol TabBarDataDelegate: AnyObject {
    func sendData(data: Any)
}
import UIKit
import AVFoundation
import MediaPlayer
import StoreKit
import DropDown
import Agrume
import AVKit
//let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
var currentItem: LibraryItem!
class PlayerViewController: UIViewController,TabBarDataDelegate {
    func sendData(data: Any) {
       
    }
    
    
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var optionsIndicatorButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var rewindButton: UIButton!
    @IBOutlet weak var maxTimeLabel: UILabel!
    @IBOutlet weak var timeSeparator: UILabel!
    @IBOutlet weak var leftVerticalView: UIView!
    @IBOutlet weak var remainingTime:UILabel!
    @IBOutlet weak var sliderView: ProgressSlider!
    @IBOutlet weak var percentageLabel: UILabel!
    @IBOutlet weak var chaptersButton: UIButton!
    @IBOutlet weak var speedEscalationButton: UIButton!
    @IBOutlet weak var remainingButton: UIButton!
    @IBOutlet weak var speedButton: UIButton!
    @IBOutlet weak var sleepButton: UIButton!
    @IBOutlet weak var speedlbl: UILabel!
    @IBOutlet weak var speedlbl2: UILabel!
    @IBOutlet weak var totalbookTimelbl: UILabel!
    @IBOutlet weak var remaininglbl: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var dropSpeedEscTimeDropImgV: UIImageView!
    @IBOutlet weak var sleepTimerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var chapter: UILabel!
    @IBOutlet weak var dropSpeedEscTimeBtn: UIButton!
    @IBOutlet weak var dropSpeedEscTimeLbl: UILabel!
    @IBOutlet weak var suffleBtn: UIButton!
    @IBOutlet weak var repeatOrLeaniearBtn: UIButton!
    @IBOutlet weak var grandTotalTime: UILabel!
    @IBOutlet weak var wordPerMinuteLbl: UILabel!
    @IBOutlet weak var timeSavedMinute: UILabel!
   
    var currentValue: Float = 0.1
    weak var delegate: TabBarDataDelegate?
    private let playImage = UIImage(named: "Group 4")
    private let pauseImage = UIImage(named: "21")
    private var coverImage = UIImage()
    private var routePickerView: AVRoutePickerView!

    private let topMenu = DropDown()
    var taponMini = false
    lazy var dropDowns: [DropDown] = {
        return [
            self.topMenu
        ]
    }()
    let queue = OperationQueue()
    var library = NewDataMannagerClass.getLibrary()
    var items: [LibraryItem] {
        guard self.library != nil else {
            return []
        }
        
        return self.library.items?.array as? [LibraryItem] ?? []
    }
    var playlist: Playlist!
    
    var plalistItems: [LibraryItem] {
        return self.playlist.books?.array as? [LibraryItem] ?? []
    }
    //timer to update sleep time
    
    var sleepTimer:Timer!
    var cIndex = 0
    var tapDelgate:TapOnOptions?
    //MARK: Lifecycle
    var book: Book? {
        didSet {
            guard let book = self.book else {
                return
            }
            
            self.coverImage =  book.artwork
            
        }
    }
    private var currentTimeInContext: TimeInterval {
        guard let book = self.book else {
            return 0.0
        }
        
        //        guard book.hasChapters, let start = book.currentChapter?.start else {
        //            return book.currentTime
        //        }
        
        return book.currentTime
    }
    private var BookcurrentTimeInContext: TimeInterval {
        guard let book = self.book else {
            return 0.0
        }
        
        return book.currentTime
    }
    
    private var maxTimeInContext: TimeInterval {
        guard let book = self.book else {
            return 0.0
        }
        
        //        guard book.hasChapters, let duration = book.currentChapter?.duration else {
        //            return book.duration
        //        }
        
        return book.duration
    }
    var chapters: [Chapter]?
    override func viewDidLoad() {
        super.viewDidLoad()
        playButton.layer.cornerRadius = 25
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let sceneDelegate = scene.delegate as? SceneDelegate {
               
                if let url = sceneDelegate.pUrl{
                 //   self.showToast("\(url)")
                    self.openThroughURL(fileURL: url)
                }else {
                   // self.showToast("no purl")
                }
            }else{
                self.showToast("no Scene delegate")
            }

        }
                
        setupAudioSession()
        setupRoutePickerView()
        
        //Drop shadow on cover view
        coverImageView.layer.shadowColor = UIColor.black.cgColor
        coverImageView.layer.shadowOffset = CGSize(width: 0, height: 4)
        coverImageView.layer.shadowOpacity = 0.6
        coverImageView.layer.shadowRadius = 6.0
        coverImageView.clipsToBounds = false
        
        modalPresentationCapturesStatusBarAppearance = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateTimer), name: Notification.Name.AudiobookPlayer.escTime, object: nil)
        
        self.speedEscalationButton.addTarget(self, action: #selector(speedEscBtnTap(_:)), for: .touchUpInside)
        self.remainingButton.addTarget(self, action: #selector(remaingBtnTap(_:)), for: .touchUpInside)
        
        // - > For New Player
        UIApplication.shared.beginReceivingRemoteControlEvents()
        NotificationCenter.default.addObserver(self, selector: #selector(self.bookReady(_:)), name: Notification.Name.AudiobookPlayer.bookReady, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.bookChange(_:)), name: Notification.Name.AudiobookPlayer.bookChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBookPlay), name: Notification.Name.AudiobookPlayer.bookPlayed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBookPause), name: Notification.Name.AudiobookPlayer.bookPaused, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBookEnd), name: Notification.Name.AudiobookPlayer.bookEnd, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onPlayback), name: Notification.Name.AudiobookPlayer.bookPlaying, object: nil)
        let id = UserDetail.shared.getPreviousUserId()
        let currentId = UserDetail.shared.getUserId()
        print(id,currentId,"checkingIds")
        if id == currentId {
            self.loadFiles()
           
        }else{
            self.removeFiles()
            
        }
        UserDetail.shared.setPreviousUserId(currentId)
        self.loadLibrary()
        self.loadPreviousBook()
    }
    
    private func loadPreviousBook() {
        guard let identifier = UserDefaults.standard.string(forKey: UserDefaultsConstants.lastPlayedBook),
        let item = PlayerManager.shared.getbookInLibrary(with: identifier) else {
            return
        }
        
        currentItem = item
        currentBok = item
      PlayerManager.shared.load([item]) { (loaded) in
            guard loaded else {
                return
            }
            
            NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.playerDismissed, object: nil, userInfo: nil)
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool){
        guard let c = currentBok else{return}
        book = c
        self.currentValue = PlayerManager.shared.speed
        if !currentBok.hasChapters {
            
            self.chaptersButton.isHidden = true
        }else{
            self.chaptersButton.isHidden = false
        }
        
        let speedEscTime = UserDefaults.standard.object(forKey: "speedEscTime") as? Int ?? 1
        self.dropSpeedEscTimeLbl.text = "\(speedEscTime)"
        
        
        if PlayerManager.shared.remaingCheck == true {
            self.remainingButton.tag = 1
            remainingButton.setImage(UIImage(named: "fontisto_toggle-off"), for: .normal)
            remaininglbl.text = "Remaining"
            //fontisto_toggle-off,Remaining
        }else{
            self.remainingButton.tag = 0
            
            remainingButton.setImage(UIImage(named: "Group-7"), for: .normal)
            remaininglbl.text = "Completed"
        }
        
        let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
        if PlayerManager.shared.speedEsalbutton == true {
            self.speedEscalationButton.tag = 1
            
            if d {
                speedEscalationButton.setImage(nil, for: .normal)
                speedEscalationButton.setBackgroundImage(UIImage(named: "fontisto_toggle-off"), for: .normal)
            }else{
                speedEscalationButton.setBackgroundImage(nil, for: .normal)
                speedEscalationButton.setImage(UIImage(named: "fontisto_toggle-off"), for: .normal)
            }
            
        }else{
            self.speedEscalationButton.tag = 0
            if d {
                speedEscalationButton.setImage(nil, for: .normal)
                speedEscalationButton.setBackgroundImage(UIImage(named: "Group-7"), for: .normal)
            }else{
                speedEscalationButton.setBackgroundImage(nil, for: .normal)
                speedEscalationButton.setImage(UIImage(named: "Group-7"), for: .normal)
            }
            
        }
        
        self.coverImageView.image = self.coverImage
        
        PlayerManager.shared.chapterArray = self.book?.chapters?.array as? [Chapter]
        //        print(PlayerManager2.shared.chapterArray.count,"log 202")
        
        
        self.setProgress()
        self.loadLibrary()
    }
    private func setupAudioSession() {
           let audioSession = AVAudioSession.sharedInstance()
           do {
               try audioSession.setCategory(.playback, mode: .default, options: [])
               try audioSession.setActive(true)
           } catch {
               print("Failed to set up audio session: \(error)")
           }
       }
       
       
       // Set up AVRoutePickerView (Hidden)
       private func setupRoutePickerView() {
           routePickerView = AVRoutePickerView(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
           routePickerView.isHidden = true
           self.view.addSubview(routePickerView)
       }
    
    @objc func removeFiles() {}
    func loadLibrary() {
        self.library = NewDataMannagerClass.getLibrary()
        NewDataMannagerClass.notifyPendingFiles()
        if let curr = currentItem {
            
        }else{
            currentItem = self.items.first
        }
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        
        if let navigationController = segue.destination as? UINavigationController,
           let viewController = navigationController.viewControllers.first as? ChaptersViewController,
           let currentChapter = self.book?.currentChapter {
            viewController.chapters = self.book?.chapters?.array as? [Chapter]
            viewController.currentChapter = currentChapter
            viewController.didSelectChapter = { selectedChapter in
               
                PlayerManager.shared.play()
                PlayerManager.shared.jumpTo(selectedChapter.start + 0.01)
            }
        }
        
    }
    //For New Player
    func openPlayList(){
        guard let book = currentItem as? Book  else {
          self.showToast("Book have no chapter")
            return
        }
    }
    @objc func onPlayback() {
        self.setProgress()
    }
    
    
    private func setProgress() {
        if PlayerManager.shared.isPlaying{
            let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
            if d {
                self.playButton.setImage(nil, for: .normal)
                self.playButton.setBackgroundImage(self.pauseImage, for: .normal)
            }else{
                self.playButton.setBackgroundImage(nil, for: .normal)
                self.playButton.setImage(self.pauseImage, for: .normal)
            }
        }else{
            let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
            if d {
                self.playButton.setImage(nil, for: .normal)
                self.playButton.setBackgroundImage(UIImage(named: "playbtn"), for:.normal)
            }else{
                self.playButton.setBackgroundImage(nil, for: .normal)
                self.playButton.setImage(self.playImage, for: .normal)
            }
        }
        guard let book = self.book else {
            
            self.percentageLabel.text = ""
            
            return
        }
        
        self.authorLabel.text = self.book?.author
        self.titleLabel.text = self.book?.title
     
                
        self.setChapterLabel()
        
        // self.maxTimeLabel.text = "\(self.formatTime2(self.maxTimeInContext))"
            self.updateTimer2()
        if  PlayerManager.shared.speedEsalbutton {
            self.dropSpeedEscTimeBtn.isEnabled = true
            if traitCollection.userInterfaceStyle == .dark {
                // Dark mode is active
                self.dropSpeedEscTimeLbl.textColor = .white
                
            } else {
                self.dropSpeedEscTimeDropImgV.tintColor = .black
               
                print("Light Mode is active")
            }

        }else{
            self.dropSpeedEscTimeBtn.isEnabled = false
            self.dropSpeedEscTimeLbl.textColor = .gray
            self.dropSpeedEscTimeDropImgV.tintColor = .gray
        }
        if !self.sliderView.isTracking {
            //self.currentTimeLabel.text = self.formatTime2(self.currentTimeInContext)
        }
        
        
        guard book.hasChapters, let chapters = book.chapters, let currentChapter = book.currentChapter else {
            if !self.sliderView.isTracking {
                if PlayerManager.shared.remaingCheck {
                    let r = 100 - Int(round(book.progress * 100))
                    self.percentageLabel.text = "\(r)%"
                }else{
                    self.percentageLabel.text = "\(Int(round(book.progress * 100)))%"
                }
                self.chapter.text = ""
                self.sliderView.value = Float(book.progress)
                self.sliderView.setNeedsDisplay()
            }
            
            return
        }
        if PlayerManager.shared.remaingCheck {
            let r = 100 - Int(round(book.progress * 100))
            self.percentageLabel.text = "\(r)%"
        }else{
            self.percentageLabel.text = "\(Int(round(book.progress * 100)))%"
        }
        self.percentageLabel.isHidden = false
        self.chapter.text = "Chapter \(currentChapter.index) of \(chapters.count)"
        if !self.sliderView.isTracking {
            self.sliderView.value = Float(book.progress)
            self.sliderView.setNeedsDisplay()
        }
        
    }
    
    private func setChapterLabel() {
        guard let book = self.book, book.hasChapters, let currentChapter = book.currentChapter else {
            
            self.chapter.text = ""
            
            
            
            return
        }
       
        
        
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (context) in
            let orientation = UIApplication.shared.statusBarOrientation
            
            if orientation.isLandscape {
                self.sleepTimerWidthConstraint.constant = 20
            } else {
                self.sleepTimerWidthConstraint.constant = 30
            }
            
        })
    }
    
    @objc func sliderChanged(_ sender: UISlider) {    }
//    var tipView: EasyTipView?
    @IBAction func infoBtnTap(_ sender:UIButton){
//        if sender.tag == 1 {
//                // Hide the tipView if it's already shown
//                tipView?.dismiss()
//                sender.tag = 0
//            } else {
//                // Show the tipView if it's not already shown
//                var preferences = EasyTipView.Preferences()
//                preferences.drawing.font = UIFont(name: "Futura-Medium", size: 13)!
//                preferences.drawing.foregroundColor = UIColor.white
//                preferences.drawing.backgroundColor = #colorLiteral(red: 0.3098039216, green: 0, blue: 0.3921568627, alpha: 1)
//                preferences.drawing.arrowPosition = EasyTipView.ArrowPosition.top
//
//                tipView = EasyTipView(text: "Gradually increases playback speed automatically every 1, 2, 3, 4 or 5 minutes.", preferences: preferences)
//                tipView?.show(forView: sender, withinSuperview: self.view)
//                sender.tag = 1
//            }
    }
    
    
    @IBAction func btnSuffle_Action(_ sender: UIButton) {
        PlayerManager.shared.playbackMode = .shuffleMode
    }
    
    @IBAction func btnReapte_Action(_ sender: UIButton) {
        switch PlayerManager.shared.playbackMode {
        case .shuffleMode :
            PlayerManager.shared.playbackMode = .linearMode
            self.repeatOrLeaniearBtn.setImage(UIImage(named: "RepeateIcon"), for: .normal)
        case .linearMode:
            self.repeatOrLeaniearBtn.setTitle(nil, for: .normal)
            self.repeatOrLeaniearBtn.setImage(UIImage(named: "repeatOnceIcon"), for: .normal)//repeatOnceIcon
            PlayerManager.shared.playbackMode = .repeatMode
        case .repeatMode :
            self.repeatOrLeaniearBtn.setImage(UIImage(named: "noRpeat"), for: .normal)
            PlayerManager.shared.playbackMode = .off
        case .off :
            PlayerManager.shared.playbackMode = .linearMode
            self.repeatOrLeaniearBtn.setTitle(nil, for: .normal)
            self.repeatOrLeaniearBtn.setImage(UIImage(named: "RepeateIcon"), for: .normal)
       
        }
       
        
    }
    
    @IBAction func btnShowPlayList_Action(_ sender: Any) {
        self.openPlayList()
    }
    
    @IBAction func btnAddBookmark_Action(_ sender: Any) {
        
        let vc: BookmarkPopUpVC = self.storyboard?.instantiateViewController(withIdentifier: "BookmarkPopUpVC") as! BookmarkPopUpVC
        vc.playerstaus = PlayerManager.shared.isPlaying
        vc.delegateBookmarkVC = self
        vc.modalPresentationStyle = .overCurrentContext
        self.present(vc, animated: false)
        
    }
    
    
    @IBAction func presentMore(_ sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MoreViewController") as! MoreViewController
        
        self.presentModal(vc, animated: true, completion: nil)
    }
    
    
    @objc func remaingBtnTap(_ sender: UIButton) {
        let c = Double(self.book?.duration ?? 0)
        let roundedX = Double(round(PlayerManager.shared.speed * 10) / 10)
        let d = c / roundedX
        let maxDuration = Int(c)
        
        let cureenTime = Int(BookcurrentTimeInContext)
        if sender.tag == 0 {
            let r = 100 - Int(round((book?.progress ?? 0) * 100))
            self.percentageLabel.text = "\(r)%"
            remainingButton.setImage(UIImage(named: "fontisto_toggle-off"), for: .normal)
            let r1 = maxDuration - cureenTime
            self.remainingTime.text = self.formatTime(r1)
            
            remaininglbl.text = "Remaining"
            
            PlayerManager.shared.remaingCheck = true
            sender.tag = 1
        }else{
            
            remainingButton.setImage(UIImage(named: "Group-7"), for: .normal)
            
            self.remainingTime.text = "\(self.formatTime(cureenTime))"
            remaininglbl.text = "Completed"
            let r = Int(round((book?.progress ?? 0) * 100))
            self.percentageLabel.text = "\(r)%"
            PlayerManager.shared.remaingCheck = false
            sender.tag = 0
        }
        
        
    }
    var preSpeed:Float = 1.0
    @objc func speedEscBtnTap(_ sender: UIButton) {
        let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
        if sender.tag == 0 {
            sender.tag = 1
            if d {
                speedEscalationButton.setImage(nil, for: .normal)
                speedEscalationButton.setBackgroundImage(UIImage(named: "fontisto_toggle-off"), for: .normal)
            }else{
                speedEscalationButton.setBackgroundImage(nil, for: .normal)
                speedEscalationButton.setImage(UIImage(named: "fontisto_toggle-off"), for: .normal)
            }
            
            //PlayerManager.sharedInstance.setSpeed(preSpeed)
            self.dropSpeedEscTimeBtn.isEnabled = true
            if traitCollection.userInterfaceStyle == .dark {
                // Dark mode is active
                self.dropSpeedEscTimeLbl.textColor = .white
                self.dropSpeedEscTimeDropImgV.tintColor = .white
                print("Dark Mode is active")
            } else {
                self.dropSpeedEscTimeDropImgV.tintColor = .black
                self.dropSpeedEscTimeLbl.textColor = .black
               
                print("Light Mode is active")
            }

            PlayerManager.shared.speedEsalbutton = true
            PlayerManager.shared.speed += 0.1
            PlayerManager.shared.speedEscalationStart()
        }else{
            sender.tag = 0
            if d {
                speedEscalationButton.setImage(nil, for: .normal)
                speedEscalationButton.setBackgroundImage(UIImage(named: "Group-7"), for: .normal)
            }else{
                speedEscalationButton.setBackgroundImage(nil, for: .normal)
                speedEscalationButton.setImage(UIImage(named: "Group-7"), for: .normal)
            }
            self.dropSpeedEscTimeBtn.isEnabled = false
            self.dropSpeedEscTimeLbl.textColor = .gray
            self.dropSpeedEscTimeDropImgV.tintColor = .gray
            PlayerManager.shared.speedEsalbutton = false
            PlayerManager.shared.speedEscalationStop()
            //  self.preSpeed =  PlayerManager2.shared.speed
            //  PlayerManager2.shared.speed = preSpeed
            
        }
    }
    @IBAction func showImgBtnTap(_ sender:UIButton){
        
        if let img = coverImageView.image {
            let agrume = Agrume(image: img)
            agrume.show(from: self)
            
            // Hide the image viewer after 20 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                agrume.dismiss()
            }
        }
    }
    @IBAction func presentChapter(_ sender: UIButton) {
        //        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        //        let vc = storyboard.instantiateViewController(withIdentifier: "ChaptersViewController") as! ChaptersViewController
        //
        //        self.present(vc, animated: true, completion: nil)
    }
    
    @IBAction func nextChapter(_ sender: UIButton) {
        guard let book = self.book else {
            return
        }
        if book.hasChapters {
            handleNextChapterAction()
        }else{
            self.showToast("Book have no chapter")
        }
        
        
    }
    
    @IBAction func previousChapter(_ sender: UIButton) {
        guard let book = self.book else {
            return
        }
        
        if book.hasChapters {
            handlePreviousChapterAction()
        }else{
            self.showToast("Book have no chapter")
        }
        
        
    }
    
    @IBAction func btnDecrease_Action(_ sender: Any) {
        
        
        if currentValue >= 0 {
            
            currentValue =  currentValue - 0.1
            print(currentValue,"currentValue")
            if currentValue > 0.0 {
                let currentValue1 = round(currentValue * 100) / 100.0
                print(currentValue1,"currentValue")
                self.setSpeed(currentValue: currentValue1)
            }
            
        } else {
            let a:Float = 0.1
            let currentValue1 = round(a * 100) / 100.0
            print(currentValue1,"currentValue")
            self.setSpeed(currentValue: currentValue1)
            print("you cant.")
        }
    }
    
    @IBAction func btnIncrease_Action(_ sender: Any) {
        
        if currentValue <= 10 {
            currentValue =  currentValue + 0.1
            var currentValue1 = round(currentValue * 100) / 100.0
            print(currentValue1,"currentValue")
            self.setSpeed(currentValue: currentValue1)
        } else {
            print("you cant.")
        }
    }
    
    // previousChapter
    func handleNextChapterAction() {
        
        if #available(iOS 10.0, *) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else {
            // Fallback on earlier versions
        }
        
        if let currentChapter = self.book?.currentChapter{
            
            if let nextChapter = PlayerManager.shared.nextChapter(after: currentChapter){
                PlayerManager.shared.jumpTo(nextChapter.start + 0.01)
            }
        } else {
            let result = self.nextBookOfPlayList()
            guard !self.plalistItems.isEmpty else {return}
            guard let index = result.1 else {return}
            guard let books = Array(self.plalistItems.suffix(from: index)) as? [Book] else {
                return
            }
            
            self.setupPlayer(books: books)
        }
        
    }
    
    func handlePreviousChapterAction() {
        
        if #available(iOS 10.0, *) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else {
            // Fallback on earlier versions
        }
        if let currentChapter = self.book?.currentChapter{
            
            if let nextChapter = PlayerManager.shared.previousChapter(after: currentChapter){
                PlayerManager.shared.jumpTo(nextChapter.start + 0.01)
                
            }
        } else {
            let result = self.nextBookOfPlayList()
            guard !self.plalistItems.isEmpty else {return}
            guard let index = result.1 else {return}
            guard let books = Array(self.plalistItems.suffix(from: index)) as? [Book] else {
                return
            }
            
            self.setupPlayer(books: books)
        }
        
    }
    func handleNextBookAction() {
        
        if #available(iOS 10.0, *) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            
        } else {
            // Fallback on earlier versions
        }
        
        if let currentItem1 = currentBok{
            if var book =  PlayerManager.shared.getNextBookInLibrary(after: currentItem1){
                if  Int(book.currentTime) == Int(book.duration){
                    book.currentTime = 0.0
                }
                currentBok = book
                 self.setupPlayer(books: [book])
            }
//            let result = self.nextBook(after: currentItem1)
//            guard let nextItem = result.0 else{return}
//            guard let index = result.1 else{return}
//            currentItem = nextItem
//            
//            if let book = nextItem as? Book {
//                self.playlist = nil
//                self.setupPlayer(books: [book])
//                
//            } else if let playlist = nextItem as? Playlist {
//                
//                PlayerManager.shared.currentPlayList = playlist
//                PlayerManager.shared.currentPlayListIndex = index
//                self.playlist = playlist
//                self.setupPlayer(books: playlist.getRemainingBooks())
//                
//            }
        } else {
            
        }
    }
    
    func handlePreviousBookAction() {
        
        if #available(iOS 10.0, *) {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } else {
            // Fallback on earlier versions
        }
        
     
            if let currentItem1 = currentBok{
                if var book =  PlayerManager.shared.getPreviousBookInLibrary(before: currentItem1){
                    if  Int(book.currentTime) == Int(book.duration){
                        book.currentTime = 0.0
                    }
                    currentBok = book
                     self.setupPlayer(books: [book])
                }
                
//            let result = self.previousBook(after: currentItem1)
//            guard let previousItem = result.0 else{return}
//            guard let index = result.1 else{return}
//            currentItem = previousItem
//            if let book = previousItem as? Book {
//                self.playlist = nil
//                self.setupPlayer(books: [book])
//                
//            } else if let playlist = previousItem as? Playlist {
//                
//                PlayerManager.shared.currentPlayList = playlist
//                PlayerManager.shared.currentPlayListIndex = index
//                self.playlist = playlist
//                self.setupPlayer(books: playlist.getRemainingBooks())
//                
//            }
            
            
            
        } else {
            
            
        }
        
        
    }
    
    func setupPlayer(books: [Book]) {
        // Make sure player is for a different book
        guard let book = books.first else {
            
            return
            
        }
        
        guard let currentBook = PlayerManager.shared.currentBook, currentBook.fileURL == book.fileURL else {
            // Handle loading new player
            self.loadPlayer(books: books)
            
            return
        }
    }
    func loadPlayer(books: [Book]) {
        guard let book = books.first else { return }
        
        guard NewDataMannagerClass.exists(book) else {
            self.showAlert("File missing!", message: "This book’s file was removed from your device. Import the file again to play the book", style: .alert)
            
            return
        }
        
        //  MBProgressHUD.showAdded(to: self.view, animated: true)
        
        // Replace player with new one
        PlayerManager.shared.load(books) { (loaded) in
            guard loaded else {
                //MBProgressHUD.hideAllHUDs(for: self.view, animated: true)
                self.showAlert("File error!", message: "This book's file couldn't be loaded. Make sure you're not using files with DRM protection (like .aax files)", style: .alert)
                return
            }
            //  self.showPlayerView(book: book)
            
            PlayerManager.shared.playPause()
            if !currentBok.hasChapters {
                
                self.chaptersButton.isHidden = true
            }else{
                self.chaptersButton.isHidden = false
            }
        }
    }
    func previousBook(after book: LibraryItem) -> (LibraryItem?,Int?) {
        guard !self.items.isEmpty else {
            return (nil,nil)
        }
        
        guard let index = (self.items.index { (item) -> Bool in
            
            return item.title == book.title
            
        })else{return (nil,nil)}
        
        if index == 0 { return (nil,nil)}
        return (self.items[index - 1],(index - 1))
    }
    
    
    func nextBook(after book: LibraryItem) -> (LibraryItem?,Int?) {
        
        guard !self.items.isEmpty else {
            return (nil,nil)
        }
        
        if book == self.items.last { return (nil,nil )}
        guard let index = (self.items.index { (item) -> Bool in
            
            return item.title == book.title
            
        })else{return (nil,nil)}
        return (self.items[index + 1],(index + 1))
    }
    
    func nextBookOfPlayList() -> (LibraryItem?,Int?) {
        guard !self.plalistItems.isEmpty else {
            return (nil,nil)
        }
        
        guard let currentBook = currentBok,
              let index = self.playlist.itemIndex(with: currentBook.fileURL)else {
            return (nil,nil)
        }
        if (index + 1) == plalistItems.count{ return (nil,nil)}
        
        return (self.plalistItems[index + 1],(index + 1))
    }
    func previousBookOfPlayList() -> (LibraryItem?,Int?) {
        guard !self.plalistItems.isEmpty else {
            return (nil,nil)
        }
        
        guard let currentBook = currentBok,
              let index = self.playlist.itemIndex(with: currentBook.fileURL)else {
            return (nil,nil)
        }
        
        
        if index == 0 { return (nil,nil) }
        return (self.plalistItems[index - 1],(index - 1))
    }
    
    @IBAction func presentSpeed(_ sender: UIButton) {
        
        let vc:ListeningSpeedVC = self.storyboard?.instantiateViewController(withIdentifier: "ListeningSpeedVC") as! ListeningSpeedVC
        
        vc.delegateSpeedListeningVC = self
        
        let myDouble =  PlayerManager.shared.currentSpeed
        let doubleStr = String(format: "%.2f", myDouble) // "3.14"
        print(doubleStr,"doubleStr")
        vc.currentValue = Float(doubleStr)!
        self.presentModal(vc, animated: true, completion: nil)
        
        
    }
    
    @IBAction func didSelectChapter(_ segue:UIStoryboardSegue){
        
    }
    
    @IBAction func didSelectSpeed(_ segue:UIStoryboardSegue){
        
        
    }
    
    
    @IBAction func dotSelectAction(_ sender:UIButton){
        
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
    
    
    @IBAction func dropSpeedEscBtnTap(_ sender:UIButton){
        let dropDown = DropDown()
        dropDown.anchorView = sender
        dropDown.bottomOffset = CGPoint(x: 0,  y: sender.bounds.height )
        dropDown.textColor = .black
        dropDown.cornerRadius = 5.0
        //        self.topMenu.borderWidth = 1
        //        self.topMenu.borderColor = #colorLiteral(red: 0.3842016757, green: 0.2161925137, blue: 0.7387148142, alpha: 1)
        dropDown.separatorColor = .clear
        dropDown.selectionBackgroundColor = .clear
        dropDown.backgroundColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        dropDown.dataSource.removeAll()
        dropDown.dataSource.append(contentsOf: ["1","2","3","4","5"])
        dropDown.selectionAction = { [unowned self] (index: Int, item: String) in
            print("Selected item: \(item) at index: \(index)")
            self.dropSpeedEscTimeLbl.text = item
            PlayerManager.shared.incresedSpeed = 1
            UserDefaults.standard.set(Int(item), forKey: "speedEscTime")
            dropDown.hide()
        }
        
        dropDown.show()
        
    }
    
    
    @IBAction func didPressSleepTimer(_ sender: UIButton) {
        
        
        let vc: PauseTimerVC = self.storyboard?.instantiateViewController(withIdentifier: "PauseTimerVC") as! PauseTimerVC
        
        vc.delegate1 = self
        
        self.presentModal(vc, animated: true, completion: nil)
        
    }
    
    @IBAction func didPressNextBook(_ sender: UIButton) {
        handleNextBookAction()
    }
    
    @IBAction func didPressPreviousBook(_ sender: UIButton) {
        handlePreviousBookAction()
    }
    
    @IBAction func didPressroutePicker(_ sender: UIButton) {
        for subview in routePickerView.subviews {
                  if let button = subview as? UIButton {
                      button.sendActions(for: .touchUpInside)
                      break
                  }
              }
    }
    override var preferredStatusBarUpdateAnimation : UIStatusBarAnimation {
        return .slide
    }
    var chapterBeforeSliderValueChange: Chapter?
    
    @IBAction func sliderDown(_ sender: UISlider, event: UIEvent) {
        self.chapterBeforeSliderValueChange = self.book?.currentChapter
    }
    
    @IBAction func sliderUp(_ sender: UISlider, event: UIEvent) {
        
        
        guard let book = self.book else {
            return
        }
        
        var newTime = TimeInterval(sender.value) * book.duration
        PlayerManager.shared.jumpTo(newTime)
        if let currentChapter = book.currentChapter {
            newTime = currentChapter.start + TimeInterval(sender.value) * currentChapter.duration
        }
        
        
    }
    
    @IBAction func sliderValueChanged(_ sender: UISlider, event: UIEvent) {
        // This should be in ProgressSlider, but how to achieve that escapes my knowledge
        self.sliderView.setNeedsDisplay()
        
        
        
        guard let book = self.book else {
            return
        }
        
        var newTimeToDisplay = TimeInterval(sender.value) * book.duration
        
        if let currentChapter = self.chapterBeforeSliderValueChange {
            newTimeToDisplay = TimeInterval(sender.value) * currentChapter.duration
        }
        
      //  self.currentTimeLabel.text = self.formatTime2(newTimeToDisplay)
        
        if !book.hasChapters {
            self.percentageLabel.text = "\(Int(round(sender.value * 100)))%"
        }
    }
    @objc private func bookReady(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let book = userInfo["book"] as? Book else {
            return
        }
        
        currentBok = book
        if book is Book {
            
        }else{}
        // let index = PlayerManager2.shared.currentPlayListIndex ?? 0
        // items[index].recentPlayTime = Date()
        self.viewWillAppear(true)
        // setupMiniPlayer(book: book)
    }
    @objc private func bookChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let books = userInfo["books"] as? [Book],
              let currentBook = books.first else {
            return
        }
        currentBok = currentBook
        
        PlayerManager.shared.play()
        self.viewWillAppear(true)
    }
}

extension PlayerViewController: AVAudioPlayerDelegate {
    
    //skip time forward
    @IBAction func forwardPressed(_ sender: UIButton) {
        PlayerManager.shared.forward()
    }
    
    //skip time backwards
    @IBAction func rewindPressed(_ sender: UIButton) {
        PlayerManager.shared.rewind()
    }
    
    //toggle play/pause of book
    @IBAction func playPressed(_ sender: UIButton) {
        if !PlayerManager.shared.isPlaying {
            
        }
      
        
        PlayerManager.shared.playPause()
    }
    
    //ESC timer callback (called every second)
    
    @objc func updateTimer() {
        PlayerManager.shared.currentSpeed = PlayerManager.shared.speed
        self.currentValue = PlayerManager.shared.speed
        print(PlayerManager.shared.incresedSpeed,"cureenESCTimeCount")
        let speedEscTime = UserDefaults.standard.object(forKey: "speedEscTime") as? Int ?? 1
        let t = speedEscTime*60
        if PlayerManager.shared.speedEsalbutton == true {
            if  PlayerManager.shared.currentSpeed < 10.1 {
                //print(Int(self.currentTimeInContext),t)
                print(PlayerManager.shared.incresedSpeed,"cureenESCTimeCount",t)
                if Int(PlayerManager.shared.incresedSpeed) % t == 0 {
                    
                    PlayerManager.shared.currentSpeed += 0.1
                    
                    let roundedX = Double(round(PlayerManager.shared.currentSpeed * 10) / 10)
                    
                    PlayerManager.shared.speed = Float(roundedX)
                }
                
            }
            
            
        }else{
            
        }
        
    }
    func updateTimer2() {
        //         PlayerManager2.shared.currentSpeed = PlayerManager2.shared.speed
        //      //  print(PlayerManager.sharedInstance.speedEsalbutton,cureenTime)
        //         let speedEscTime = UserDefaults.standard.object(forKey: "speedEscTime") as? Int ?? 1
        //         let t = speedEscTime*60
        //         if PlayerManager2.shared.speedEsalbutton == true {
        //            if  PlayerManager.sharedInstance.currentSpeed < 10.1 {
        //              print(Int(self.currentTimeInContext),t)
        //                if Int(self.currentTimeInContext) % t == 0 {
        //
        //                    PlayerManager2.shared.currentSpeed += 0.1
        //
        //                    let roundedX = Double(round(PlayerManager2.shared.currentSpeed * 10) / 10)
        //
        //                    PlayerManager2.shared.speed = Float(roundedX)
        //                }
        //
        //            }
        //
        //
        //        }else{
        //
        //        }
        
        let originalValue: Double = Double(PlayerManager.shared.speed)
        let roundedValue = String(format: "%.1f", originalValue)
        print(roundedValue) // This will print "12.3"
        
        self.speedlbl.text =  "\(roundedValue)x"
        self.speedlbl2.text =  "\(roundedValue)x"
        let c = Double(self.book?.duration ?? 0)
        self.grandTotalTime.text = "\(self.formatTime(Int(c))) (\(1)x)"
        let roundedX = Double(round(PlayerManager.shared.speed * 10) / 10)
        let d = c / roundedX
        let e = c - d
        self.timeSavedMinute.text = "Time Saved @ \(roundedValue)x → \(self.formatTime(Int(e)))"
        self.maxTimeLabel.text = "\(self.formatTime(Int(d)))"
        self.totalbookTimelbl.text = "\(self.formatTime(Int(d))) (\(roundedValue)x)"
        let maxDuration = Int(c)
        let cureenTime = Double(BookcurrentTimeInContext)
        let roundedX2 = Double(round(PlayerManager.shared.speed * 10) / 10)
        let d2 = cureenTime / roundedX2
        //        self.sliderView.value = percentage
        //        //update current time label
        //        self.currentTimeLabel.text = timeText
        //        PlayerManager.sharedInstance.currentBookCurrentTime = timeText
        //update book read percentage
        if remainingButton.tag == 0 {
            self.remainingTime.text = "\(self.formatTime(Int(d2)))"
            // remaininglbl.text = "Completed"
        }else{
            
            let r = d - d2
            self.remainingTime.text = self.formatTime(Int(r))
            //remaininglbl.text = "Remaning"
        }
        self.wordPerMinuteLbl.text = "WPM ≈ \(calculateRoundedSpeed(totalDuration: PlayerManager.shared.audioPlayer?.duration ?? 0.0, currentSpeed: Double(PlayerManager.shared.audioPlayer?.rate ?? 0)))"
        //      print("Rounded Speed:", roundedSpeed)
        
        
    }
     func openThroughURL(fileURL:URL) {
         //self.showAlert(for: "\(fileURL) aya")
   
        let destinationFolder = NewDataMannagerClass.getProcessedFolderURL()
        
        NewDataMannagerClass.processFile(at: fileURL, destinationFolder: destinationFolder) { (processedURL) in
            guard let processedURL = processedURL else {
              
                return
            }
            
            let bookUrl = BookURL(original: fileURL, processed: processedURL)
            self.loadFile(urls: [bookUrl])
        }
    }
    
    
    func loadFile(urls: [BookURL]) {
        self.queue.addOperation {
            NewDataMannagerClass.insertBooks(from: urls, into: nil, or: self.library) {
                NewDataMannagerClass.saveContext()
                self.loadLibrary()
            }
        }
    }
    
    func calculateRoundedSpeed(totalDuration: Double, currentSpeed: Double) -> Int {
        let roundedSpeed = Int((currentSpeed / 0.006).rounded())
        return roundedSpeed
        
    }
    //update pause reminder callback
    
    
    
    //percentage callback
    
    
    @objc func requestReview(){
        //don't do anything if flag isn't true
        guard UserDefaults.standard.bool(forKey: "ask_review") else {
            return
        }
        
        // request for review
        if #available(iOS 10.3, *),
           UIApplication.shared.applicationState == .active {
            //            SKStoreReviewController.requestReview()
            UserDefaults.standard.set(false, forKey: "ask_review")
        }
    }
    @objc private func onBookPlay() {
        let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
        if d {
            self.playButton.setImage(nil, for: .normal)
            self.playButton.setBackgroundImage(self.pauseImage, for: .normal)
            
        }else{
            self.playButton.setImage(self.pauseImage, for: .normal)
            self.playButton.setBackgroundImage(nil, for: .normal)
        }
    }
    @objc private func onBookEnd() {
        self.handleNextBookAction()
        let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
        if d {
            self.playButton.setImage(nil, for: .normal)
            self.playButton.setBackgroundImage(UIImage(named: "playbtn"), for: .normal)
        }else{
            self.playButton.setImage(self.playImage, for: .normal)
            self.playButton.setBackgroundImage(nil, for: .normal)
        }
    }
    
    @objc private func onBookPause() {
        let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
        if d {
            self.playButton.setImage(nil, for: .normal)
            self.playButton.setBackgroundImage(UIImage(named: "playbtn"), for: .normal)
        }else{
            self.playButton.setImage(self.playImage, for: .normal)
            self.playButton.setBackgroundImage(nil, for: .normal)
        }
    }
    
    @objc func bookReady(){
        
    }
    
    @objc func bookEnd() {
        // self.handleNextBookAction()
    }
    
    
    @objc func loadFiles() {
        
    }
}
extension PlayerViewController:DelegateforListeningSpeedVC,DelegateforBookmarkPopUpVC {
    func MethodforPop(string: String) {
        
    }
    
    func sendDataToFirstViewController(myData: Float) {
        
        PlayerManager.shared.speed = myData
        self.currentValue = PlayerManager.shared.speed
        let originalValue: Double = Double(PlayerManager.shared.speed)
        let roundedValue = String(format: "%.1f", originalValue)
        print(roundedValue)
        let maxDuration = Double(self.book?.duration ?? 0)
        let roundedX = Double(round(PlayerManager.shared.speed * 10) / 10)
        let c = maxDuration / roundedX
        self.maxTimeLabel.text = "\(self.formatTime(Int(c)))"
        self.totalbookTimelbl.text = "\(self.formatTime(Int(c)))" + " (\(roundedValue)x)"
        // This will print "12.3"
        
        self.speedlbl.text =  "\(roundedValue)x"
        self.speedlbl2.text =  "\(roundedValue)x"
    }
    
    func setSpeed(currentValue:Float){
        var myData:Float = 0.1
        let currentValue1 = round(currentValue * 100) / 100.0
        let dataToBeSent = currentValue1
        myData = dataToBeSent
        
        PlayerManager.shared.speed = myData
        let originalValue: Double = Double(PlayerManager.shared.speed)
        let roundedValue = String(format: "%.1f", originalValue)
        print(roundedValue)
        let maxDuration = Double(self.book?.duration ?? 0)
        let roundedX = Double(round(PlayerManager.shared.speed * 10) / 10)
        let c1 = maxDuration / roundedX
        self.maxTimeLabel.text = "\(self.formatTime(Int(c1)))"
        self.totalbookTimelbl.text = "\(self.formatTime(Int(c1)))" + " (\(roundedValue)x)"
        // This will print "12.3"
        
        self.speedlbl.text =  "\(roundedValue)x"
        self.speedlbl2.text =  "\(roundedValue)x"
        
        let c = Double(self.book?.duration ?? 0)
        self.grandTotalTime.text = "\(self.formatTime(Int(c))) (\(1)x)"
        
        let d = c / roundedX
        let e = c - d
        self.timeSavedMinute.text = "Time Saved @ \(roundedValue)x → \(self.formatTime(Int(e)))"
        self.maxTimeLabel.text = "\(self.formatTime(Int(d)))"
        self.totalbookTimelbl.text = "\(self.formatTime(Int(d))) (\(roundedValue)x)"
       
        let cureenTime = Double(BookcurrentTimeInContext)
        let roundedX2 = Double(round(PlayerManager.shared.speed * 10) / 10)
        let d2 = cureenTime / roundedX2
        //        self.sliderView.value = percentage
        //        //update current time label
        //        self.currentTimeLabel.text = timeText
        //        PlayerManager.sharedInstance.currentBookCurrentTime = timeText
        //update book read percentage
        if remainingButton.tag == 0 {
            self.remainingTime.text = "\(self.formatTime(Int(d2)))"
            // remaininglbl.text = "Completed"
        }else{
            
            let r = d - d2
            self.remainingTime.text = self.formatTime(Int(r))
            //remaininglbl.text = "Remaning"
        }
        self.wordPerMinuteLbl.text = "WPM ≈ \(calculateRoundedSpeed(totalDuration: PlayerManager.shared.audioPlayer?.duration ?? 0.0, currentSpeed: Double(PlayerManager.shared.audioPlayer?.rate ?? 0)))"
    }
    
}
extension PlayerViewController:DelegateforPauseTimer{
    func MethodforPop() {
        
    }
    
    func sendDataToPlayerVC(myData: String, PaustimerStatus: String) {
        
    }
    
    
}
protocol TapOnOptions {
    func tapped(conditionValue:Int)
}
