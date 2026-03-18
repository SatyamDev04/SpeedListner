
//  LandscapePlayerViewController.swift
//  SpeedListner
//  Created by satyam dwivedi on 31/10/25.



import UIKit
import AVFoundation
import AVKit


final class LandscapePlayerViewController: UIViewController, DelegateforListeningSpeedVC, DelegateforBookmarkPopUpVC {
   

    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    @IBOutlet weak var remainingButton: UIButton!
    @IBOutlet weak var remainingTime:UILabel!
    @IBOutlet weak var remaininglbl: UILabel!
    @IBOutlet weak var speedlbl: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var speedEscalationButton: UIButton!
    
    private let playImage = UIImage(named:"landPlayImg")
    private let pauseImage = UIImage(named: "landPauseImg")
    var library = NewDataMannagerClass.getLibrary()
    private var routePickerView: AVRoutePickerView!
    private var coverImage = UIImage()
    var currentValue: Float = 0.1
    private let closeButton = UIButton(type: .system)
    private var isPlaying: Bool {
        return PlayerManager.shared.isPlaying
    }
    
    var items: [LibraryItem] {
        guard self.library != nil else {
            return []
        }
        
        return self.library.items?.array as? [LibraryItem] ?? []
    }
    var book: Book? {
        didSet {
            guard let book = self.book else {
                return
            }
            
            self.coverImage =  book.artwork
            
        }
    }

    private var BookcurrentTimeInContext: TimeInterval {
        guard let book = self.book else {
            return 0.0
        }
        
        return book.currentTime
    }
    
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        switch AppOrientationManager.shared.current {
        case .lockHorizontal:
            return .landscape
            
        case .lockVertical:
            return .portrait
            
        case .normal:
            return .allButUpsideDown
        }
    }

    override var shouldAutorotate: Bool {
        switch AppOrientationManager.shared.current {
        case .lockHorizontal:
            return false
            
        case .lockVertical:
            return false
            
        case .normal:
            return true    
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
        self.remainingButton.addTarget(self, action: #selector(remaingBtnTap(_:)), for: .touchUpInside)
        self.speedEscalationButton.addTarget(self, action: #selector(speedEscBtnTap(_:)), for: .touchUpInside)
        NotificationCenter.default.addObserver(self, selector: #selector(self.bookReady(_:)), name: Notification.Name.AudiobookPlayer.bookReady, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.bookChange(_:)), name: Notification.Name.AudiobookPlayer.bookChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBookPlay), name: Notification.Name.AudiobookPlayer.bookPlayed, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBookPause), name: Notification.Name.AudiobookPlayer.bookPaused, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onBookEnd), name: Notification.Name.AudiobookPlayer.bookEnd, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateTimer), name: Notification.Name.AudiobookPlayer.escTime, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.onPlayback), name: Notification.Name.AudiobookPlayer.bookPlaying, object: nil)
        self.loadLibrary()
        setupAudioSession()
        setupRoutePickerView()
//        if AppOrientationManager.shared.current == .lockHorizontal {
//            setupCloseButton()
//        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool){
        guard let c = currentBok else{return}
        book = c
        self.currentValue = PlayerManager.shared.speed
    
        let speedEscTime = UserDefaults.standard.object(forKey: "speedEscTime") as? Int ?? 1
     
        if PlayerManager.shared.remaingCheck == true {
            self.remainingButton.tag = 1
            remainingButton.setBackgroundImage(UIImage(named: "fontisto_toggle-off"), for: .normal)
            remaininglbl.text = "Remaining"
        }else{
            self.remainingButton.tag = 0
            
            remainingButton.setBackgroundImage(UIImage(named: "Group-7"), for: .normal)
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
                speedEscalationButton.setBackgroundImage(UIImage(named: "fontisto_toggle-off"), for: .normal)
            }
            
        }else{
            self.speedEscalationButton.tag = 0
            if d {
                speedEscalationButton.setImage(nil, for: .normal)
                speedEscalationButton.setBackgroundImage(UIImage(named: "Group-7"), for: .normal)
            }else{
                speedEscalationButton.setBackgroundImage(nil, for: .normal)
                speedEscalationButton.setBackgroundImage(UIImage(named: "Group-7"), for: .normal)
            }
            
        }
        
        self.coverImageView.image = self.coverImage
        
        PlayerManager.shared.chapterArray = self.book?.chapters?.array as? [Chapter]
     
        self.setProgress()
        self.loadLibrary()
    }
    
    private func setupCloseButton() {
        
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        let image = UIImage(systemName: "xmark", withConfiguration: config)
        
        closeButton.setImage(image, for: .normal)
        closeButton.tintColor = .white
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        closeButton.layer.cornerRadius = 18
        closeButton.clipsToBounds = true
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        
        closeButton.addTarget(self, action: #selector(closeLandscape), for: .touchUpInside)
        
        view.addSubview(closeButton)
        
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            closeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 36),
            closeButton.heightAnchor.constraint(equalToConstant: 36)
        ])
    }
    
    @objc private func closeLandscape() {
        AppOrientationManager.shared.current = .lockVertical
        AppOrientationManager.shared.applyOrientation(.lockVertical)
    }
    
    @objc func onPlayback() {
        self.setProgress()
    }
    
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
        setProgress()
       
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
            
            return
        }
             
            self.updateTimer2()
      
    }
    func updateTimer2() {
        
        let originalValue: Double = Double(PlayerManager.shared.speed)
        let roundedValue = String(format: "%.1f", originalValue)
        print(roundedValue) // This will print "12.3"
        
        self.speedlbl.text =  "\(roundedValue)x"
        let c = Double(self.book?.duration ?? 0)
      
        let roundedX = Double(round(PlayerManager.shared.speed * 10) / 10)
        let d = c / roundedX
        let e = c - d
      
        let maxDuration = Int(c)
        let cureenTime = Double(BookcurrentTimeInContext)
        let roundedX2 = Double(round(PlayerManager.shared.speed * 10) / 10)
        let d2 = cureenTime / roundedX2
       
        if remainingButton.tag == 0 {
            self.remainingTime.text = "\(self.formatTime(Int(d2)))"
            
        }else{
            
            let r = d - d2
            self.remainingTime.text = self.formatTime(Int(r))
         
        }
       
    }
    

    var preSpeed:Float = 1.0
    @objc func speedEscBtnTap(_ sender: UIButton) {
        
        guard !isLibraryEmpty() else {
                showToast("Please add a book to the library if already added then play")
                return
            }
        
        let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
        if sender.tag == 0 {
            sender.tag = 1
            if d {
                speedEscalationButton.setImage(nil, for: .normal)
                speedEscalationButton.setBackgroundImage(UIImage(named: "fontisto_toggle-off"), for: .normal)
            }else{
                speedEscalationButton.setBackgroundImage(nil, for: .normal)
                speedEscalationButton.setBackgroundImage(UIImage(named: "fontisto_toggle-off"), for: .normal)
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
                speedEscalationButton.setBackgroundImage(UIImage(named: "Group-7"), for: .normal)
            }
          
            PlayerManager.shared.speedEsalbutton = false
            PlayerManager.shared.speedEscalationStop()
           
        }
    }
    @objc func remaingBtnTap(_ sender: UIButton) {
        guard !isLibraryEmpty() else {
                showToast("Please add a book to the library if already added then play")
                return
            }
        
        let c = Double(self.book?.duration ?? 0)
        let roundedX = Double(round(PlayerManager.shared.speed * 10) / 10)
        let d = c / roundedX
        let maxDuration = Int(c)
        
        let cureenTime = Int(BookcurrentTimeInContext)
        if sender.tag == 0 {
            let r = 100 - Int(round((book?.progress ?? 0) * 100))
           
            remainingButton.setBackgroundImage(UIImage(named: "fontisto_toggle-off"), for: .normal)
            let r1 = maxDuration - cureenTime
            self.remainingTime.text = self.formatTime(r1)
            
            remaininglbl.text = "Remaining"
            
            PlayerManager.shared.remaingCheck = true
            sender.tag = 1
        }else{
            
            remainingButton.setBackgroundImage(UIImage(named: "Group-7"), for: .normal)
            
            self.remainingTime.text = "\(self.formatTime(cureenTime))"
            remaininglbl.text = "Completed"
            let r = Int(round((book?.progress ?? 0) * 100))
          
            PlayerManager.shared.remaingCheck = false
            sender.tag = 0
        }
        
        
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
    
  

    @objc private func increaseSpeed() {
        let s = min(PlayerManager.shared.currentSpeed + 0.1, 10.0)
        PlayerManager.shared.currentSpeed = s
        // apply to PlayerManager
        if let setRate = PlayerManager.shared.perform(Selector(("setPlaybackRate:")), with: NSNumber(value: s)) {
            _ = setRate
        }
     
    }

    @objc private func decreaseSpeed() {
        
        let s = max(PlayerManager.shared.currentSpeed - 0.1, 0.1)
        PlayerManager.shared.currentSpeed = s
        if let setRate = PlayerManager.shared.perform(Selector(("setPlaybackRate:")), with: NSNumber(value: s)) {
            _ = setRate
        }
        
    }

    @objc private func escalationToggled() {
        
    }

    @objc private func bookmarkTapped() {
        // Post a notification or call known selector to add bookmark
        NotificationCenter.default.post(name: Notification.Name("AddBookmarkFromUI"), object: nil)
    }
    private func isLibraryEmpty() -> Bool {
        return getAllBooks(from: library).isEmpty || self.book == nil
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
    
    @IBAction func rewindPressed(_ sender: UIButton) {
        guard !isLibraryEmpty() else {
                showToast("Please add a book to the library if already added then play")
                return
            }
        PlayerManager.shared.rewind()
    }
    @IBAction func playPressed(_ sender: UIButton) {
        guard !isLibraryEmpty() else {
                showToast("Please add a book to the library if already added then play")
                return
            }
        if !PlayerManager.shared.isPlaying {
            
        }
      
        
        PlayerManager.shared.playPause()
    }
    @IBAction func forwardPressed(_ sender: UIButton) {
        guard !isLibraryEmpty() else {
                showToast("Please add a book to the library if already added then play")
                return
            }
        PlayerManager.shared.forward()
    }
    @IBAction func btnDecrease_Action(_ sender: Any) {
        guard !isLibraryEmpty() else {
                showToast("Please add a book to the library if already added then play")
                return
            }
        
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
        guard !isLibraryEmpty() else {
                showToast("Please add a book to the library if already added then play")
                return
            }
        if currentValue <= 15 {
            currentValue =  currentValue + 0.1
            var currentValue1 = round(currentValue * 100) / 100.0
            print(currentValue1,"currentValue")
            self.setSpeed(currentValue: currentValue1)
        } else {
            print("you cant.")
        }
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
    
    self.speedlbl.text =  "\(roundedValue)x"
     
        
        let c = Double(self.book?.duration ?? 0)

        let d = c / roundedX
        let e = c - d
     
       
        let cureenTime = Double(BookcurrentTimeInContext)
        let roundedX2 = Double(round(PlayerManager.shared.speed * 10) / 10)
        let d2 = cureenTime / roundedX2
      
        if remainingButton.tag == 0 {
            self.remainingTime.text = "\(self.formatTime(Int(d2)))"
             remaininglbl.text = "Completed"
        }else{
            
            let r = d - d2
            self.remainingTime.text = self.formatTime(Int(r))
            remaininglbl.text = "Remaning"
        }
     
    }
    @IBAction func didPressroutePicker(_ sender: UIButton) {
        for subview in routePickerView.subviews {
                  if let button = subview as? UIButton {
                      button.sendActions(for: .touchUpInside)
                      break
                  }
              }
    
    }
    @IBAction func presentSpeed(_ sender: UIButton) {
        LandscapePlayerManager.shared.isModalBeingPresented = true
        guard !isLibraryEmpty() else {
                showToast("Please add a book to the library if already added then play")
                return
            }
        let vc:ListeningSpeedVC = self.storyboard?.instantiateViewController(withIdentifier: "ListeningSpeedVC2") as! ListeningSpeedVC
        vc.comeFrom = "landscape"
        vc.delegateSpeedListeningVC = self
        
        let myDouble =  PlayerManager.shared.currentSpeed
        let doubleStr = String(format: "%.2f", myDouble) // "3.14"
        print(doubleStr,"doubleStr")
        vc.currentValue = Float(doubleStr)!
        self.presentModal(vc, animated: true, completion: nil)
        
        
    }
    func MethodforPop() {
        
    }
    func MethodforPop(string: String) {
        
    }
    func loadLibrary() {
        self.library = NewDataMannagerClass.getLibrary()
        NewDataMannagerClass.notifyPendingFiles()
        if let curr = currentItem {
            
        }else{
            currentItem = self.items.first
        }
        
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
           
            // This will print "12.3"
            
            self.speedlbl.text =  "\(roundedValue)x"
           
        }
    
    @IBAction func btnAddBookmark_Action(_ sender: Any) {
        guard !isLibraryEmpty() else {
                showToast("Please add a book to the library if already added then play")
                return
            }
        let vc: BookmarkPopUpVC = self.storyboard?.instantiateViewController(withIdentifier: "BookmarkPopUpVC") as! BookmarkPopUpVC
        vc.playerstaus = PlayerManager.shared.isPlaying
        vc.delegateBookmarkVC = self
        vc.modalPresentationStyle = .overCurrentContext
        self.present(vc, animated: false)
        
    }
    @objc private func bookReady(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let book = userInfo["book"] as? Book else {
            return
        }
        
        currentBok = book
        if book is Book {
            
        }else{
            
        }
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
    @objc private func onBookEnd() {
        //self.handleNextBookAction()
        let d = UserDefaults.standard.object(forKey: "desable") as? Bool ?? false
        if d {
            self.playButton.setImage(nil, for: .normal)
            self.playButton.setBackgroundImage(UIImage(named: "playbtn"), for: .normal)
        }else{
            self.playButton.setImage(self.playImage, for: .normal)
            self.playButton.setBackgroundImage(nil, for: .normal)
        }
    }
}
