//
//  NewPlayerManager.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 9/5/23.
//  
//


import Foundation
import AVFoundation
import MediaPlayer

enum PlaybackMode {
    case repeatMode
    case linearMode
    case shuffleMode
    case off
}



class PlayerManager: NSObject {
    
    static let shared = PlayerManager()
    
    var audioPlayer: AVAudioPlayer?
    private var playerItem: AVPlayerItem!
    var speedEsalbutton = false
    var currentSpeed:Float = 1.0
    var currentBooks: [Book]?
    var currentPlayList:Playlist?
    var currentPlayListIndex:Int?
    var chapterArray: [Chapter]!
    var sleepCheck = false
    var remaingCheck = false
    var isRecentCheck = false
    var incresedSpeed = 1.0
    var miniPlayerIsHidden = false
    var desable_Person:Bool = false
    var playbackMode: PlaybackMode = .off
    var rePlaybooks: [Book] = []
    var currentBook: Book? {
        return self.currentBooks?.first
    }
    
    private var timer: Timer!
    var sleepTimer:Timer!
    var EscTimer:Timer!
    var index = Int()
    var bookCount = 0
    var email = ""
    var isPaused = true
    
    // 599 = 10 mins
    private let smartRewindThreshold = 599.0
    private let maxSmartRewind = 30.0
    
    func load(_ books: [Book], completion:@escaping (Bool) -> Void) {
        guard let book = books.first else {
            completion(false)
            return
        }
        if rePlaybooks.first?.fileURL == book.fileURL || rePlaybooks.isEmpty {
            rePlaybooks = books
        }else{
            
        }
        
        self.currentBooks = books
        
        // Load data on background thread
        DispatchQueue.global().async {
            // try loading the player
            guard let audioplayer = try? AVAudioPlayer(contentsOf: book.fileURL) else {
                DispatchQueue.main.async(execute: {
                    self.currentBooks = nil
                    completion(false)
                })
                return
            }
            
            self.audioPlayer = audioplayer
            
            audioplayer.delegate = self
            audioplayer.enableRate = true
            
            self.playerItem = NewDataMannagerClass.playerItem(from: book)
            PlayerManager.shared.isRecentCheck = true
            if UserDefaults.standard.bool(forKey: UserDefaultsConstants.boostVolumeEnabled) {
                audioplayer.volume = 2.0
            }
            
            // Update UI on main thread
            DispatchQueue.main.async(execute: {
                // Set book metadata for lockscreen and control center
                
                var nowPlayingInfo: [String: Any] = [
                    MPMediaItemPropertyTitle: book.title ?? "",
                    MPMediaItemPropertyArtist: book.author ?? "Unknown",
                    MPMediaItemPropertyPlaybackDuration: audioplayer.duration
                ]
                
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
                    boundsSize: book.artwork.size,
                    requestHandler: { (_) -> UIImage in
                        return book.artwork
                    }
                )
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                if book.currentTime == audioplayer.duration{
                    book.currentTime = 0.0
                }
                if book.currentTime > 0.0 {
                    self.jumpTo(book.currentTime)
                }
                
                // Set speed for player
                
                audioplayer.rate = self.speed
                
                NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.bookReady, object: nil, userInfo: ["book": book])
                
                completion(true)
            })
            print(book.fileURL,"ja kark")
            
        }
    }
    
    // Called every second by the timer
    @objc func update() {
        guard let audioplayer = self.audioPlayer, let book = self.currentBook else {
            return
        }
        
        book.currentTime = audioplayer.currentTime
        
        let isPercentageDifferent = book.percentage != book.percentCompleted || (book.percentCompleted == 0 && book.progress > 0)
        book.recentPlayTime = Date()
        book.percentCompleted = book.percentage
        
        NewDataMannagerClass.saveContext()
        
        // Notify
        if isPercentageDifferent {
            NotificationCenter.default.post(
                name: Notification.Name.AudiobookPlayer.updatePercentage,
                object: nil,
                userInfo: [
                    "progress": book.progress,
                    "fileURL": book.fileURL
                ] as [String: Any]
            )
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioplayer.currentTime
        
        // stop timer if the book is finished
        if Int(audioplayer.currentTime) == Int(audioplayer.duration) {
            if self.timer != nil && self.timer.isValid {
                self.timer.invalidate()
            }
            
            // Once book a book is finished, ask for a review
            UserDefaults.standard.set(true, forKey: "ask_review")
            NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.bookEnd, object: nil)
        }
        
        let userInfo = [
            "time": currentTime,
            "fileURL": book.fileURL
        ] as [String: Any]
        
        // Notify
        NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.bookPlaying, object: nil, userInfo: userInfo)
        
    }
    func getDataOfFile(at fileURL: URL, completion: @escaping (Data?) -> Void) {
        DispatchQueue.global().async {
            do {
                // Access the file using FileManager
                let data = try Data(contentsOf: fileURL)
                DispatchQueue.main.async {
                    completion(data)
                }
            } catch {
                // Handle errors
                print("Error reading file data: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    // MARK: - Player states
    
    var isLoaded: Bool {
        return self.audioPlayer != nil
    }
    
    var isPlaying: Bool {
        return audioPlayer?.isPlaying ?? false
    }
    
    var duration: TimeInterval {
        return audioPlayer?.duration ?? 0.0
    }
    
    var currentTime: TimeInterval {
        get {
            return audioPlayer?.currentTime ?? 0.0
        }
        
        set {
            guard let player = self.audioPlayer else {
                return
            }
            
            player.currentTime = newValue
            
            self.currentBook?.currentTime = newValue
        }
    }
    
    var speed: Float {
        get {
            
            let useGlobalSpeed = UserDefaults.standard.bool(forKey: UserDefaultsConstants.globalSpeedEnabled)
            let globalSpeed = UserDefaults.standard.float(forKey: "global_speed")
            let localSpeed = UserDefaults.standard.float(forKey: (self.currentBook?.identifier ?? "")+"_speed")
            let speed = useGlobalSpeed ? globalSpeed : localSpeed
            //PlayerManager2.shared.incresedSpeed = Double(self.currentSpeed)
            return speed > 0 ? speed : 1.0
        }
        
        set {
            guard let audioPlayer = self.audioPlayer, let currentBook = self.currentBook else {
                return
            }
            
            UserDefaults.standard.set(newValue, forKey: (currentBook.identifier ?? "unknown")+"_speed")
            
            // set global speed
            if UserDefaults.standard.bool(forKey: UserDefaultsConstants.globalSpeedEnabled) {
                UserDefaults.standard.set(newValue, forKey: "global_speed")
            }
            
            audioPlayer.rate = newValue
        }
    }
    
    var rewindInterval: TimeInterval {
        get {
            if UserDefaults.standard.object(forKey: UserDefaultsConstants.rewindInterval) == nil {
                return 10.0
            }
            
            return UserDefaults.standard.double(forKey: UserDefaultsConstants.rewindInterval)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsConstants.rewindInterval)
            
            MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [newValue] as [NSNumber]
        }
    }
    
    var forwardInterval: TimeInterval {
        get {
            if UserDefaults.standard.object(forKey: UserDefaultsConstants.forwardInterval) == nil {
                return 10.0
            }
            
            return UserDefaults.standard.double(forKey: UserDefaultsConstants.forwardInterval)
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: UserDefaultsConstants.forwardInterval)
            
            MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [newValue] as [NSNumber]
        }
    }
    
    // MARK: - Seek Controls
    
    func jumpTo(_ time: Double, fromEnd: Bool = false) {
        guard let player = self.audioPlayer else {
            return
        }
        
        player.currentTime = min(max(fromEnd ? player.duration - time : time, 0), player.duration)
        
        if !self.isPlaying, let currentBook = self.currentBook {
            UserDefaults.standard.set(Date(), forKey: "\(UserDefaultsConstants.lastPauseTime)_\(currentBook.identifier ?? "")")
        }
        
        update()
    }
    
    func jumpBy(_ direction: Double) {
        guard let player = self.audioPlayer else {
            return
        }
        
        player.currentTime += direction
        
        update()
    }
    
    func forward() {
        if speed > 1 {
            let s = Double(self.speed) * 10
            self.jumpBy(s)
        }else{
            self.jumpBy(10)
        }
    }
    
    func rewind() {
        if speed > 1 {
            let s = Double(self.speed) * 10
            self.jumpBy(-s)
        }else{
            self.jumpBy(-10)
        }
        
    }
    
    // MARK: - Playback
    
    func play(_ autoplayed: Bool = false) {
        guard let currentBook = self.currentBook, let audioplayer = self.audioPlayer else {
            return
        }
        
        UserDefaults.standard.set(currentBook.identifier, forKey: UserDefaultsConstants.lastPlayedBook)
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // @TODO: Handle error if AVAudioSession fails to become active again
        }
        
        let completed = Int(audioplayer.duration) == Int(audioplayer.currentTime)
        
        if autoplayed && completed {
            return
        }
        
        // If book is completed, reset to start
        if completed {
            audioplayer.currentTime = 0.0
        }
        
        // Handle smart rewind.
        let lastPauseTimeKey = "\(UserDefaultsConstants.lastPauseTime)_\(currentBook.identifier ?? "")"
        let smartRewindEnabled = UserDefaults.standard.bool(forKey: UserDefaultsConstants.smartRewindEnabled)
        
        if smartRewindEnabled, let lastPlayTime: Date = UserDefaults.standard.object(forKey: lastPauseTimeKey) as? Date {
            let timePassed = Date().timeIntervalSince(lastPlayTime)
            let timePassedLimited = min(max(timePassed, 0), self.smartRewindThreshold)
            let delta = timePassedLimited / self.smartRewindThreshold
            
           
            let rewindTime = pow(delta, 3) * self.maxSmartRewind
            let newPlayerTime = max(audioplayer.currentTime - rewindTime, 0)
            
            UserDefaults.standard.set(nil, forKey: lastPauseTimeKey)
            
            audioplayer.currentTime = newPlayerTime
        }
        
     
        if self.timer == nil || (self.timer != nil && !self.timer.isValid) {
            self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(update), userInfo: nil, repeats: true)
            
            RunLoop.main.add(self.timer, forMode: RunLoop.Mode.common)
        }
        
     
        audioplayer.play()
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = 1.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioplayer.currentTime
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.bookPlayed, object: nil)
        }
        
        self.update()
    }
    
    func pause() {
        guard let audioplayer = self.audioPlayer, let currentBook = self.currentBook else {
            return
        }
        
        UserDefaults.standard.set(currentBook.identifier, forKey: UserDefaultsConstants.lastPlayedBook)
        
        
        if self.timer != nil {
            self.timer.invalidate()
        }
        
        self.update()
        
        audioplayer.pause()
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = audioplayer.currentTime
        
        UserDefaults.standard.set(Date(), forKey: "\(UserDefaultsConstants.lastPauseTime)_\(currentBook.identifier ?? "")")
        
        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
           
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.bookPaused, object: nil)
        }
    }
    
    func playPause(autoplayed: Bool = false) {
        guard let audioplayer = self.audioPlayer else {
            return
        }
        
        if audioplayer.isPlaying {
            self.pause()
        } else {
            self.play()
        }
    }
    
    func stop() {
        self.audioPlayer?.stop()
        
        var userInfo: [AnyHashable: Any]?
        
        if let book = self.currentBook {
            userInfo = ["book": book]
        }
        
        self.currentBooks = []
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: Notification.Name.AudiobookPlayer.bookStopped,
                object: nil,
                userInfo: userInfo
            )
        }
    }
    
    public func nextChapter(after chapter: Chapter) -> Chapter? {
        guard !self.chapterArray.isEmpty else {
            return nil
        }
        
        if chapter == self.chapterArray.last { return nil }
        
        return self.chapterArray[Int(chapter.index)]
    }
    public func previousChapter(after chapter: Chapter) -> Chapter? {
        guard !self.chapterArray.isEmpty else {
            return nil
        }
        
        if chapter == self.chapterArray.first { return nil }
        
        return self.chapterArray[Int(chapter.index ) - 2]
    }
}



extension PlayerManager: AVAudioPlayerDelegate {
    // Leave the slider at max
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        guard flag else { return }
    
        player.currentTime = player.duration

            UserDefaults.standard.removeObject(forKey: UserDefaultsConstants.lastPlayedBook)

            self.update()

            switch playbackMode {
            case .repeatMode:
             
                player.stop()
                player.currentTime = 0
                
            
                let userInfo = ["books": self.rePlaybooks]
                NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.bookChange, object: nil, userInfo: userInfo)
                
                // Start playback again
                self.audioPlayer?.play()
            
            
        case .linearMode:
            guard let currentBook = self.currentBook else {
                print("No current book available.")
                return
            }
            
            guard var nextBook = getNextBookInLibrary(after: currentBook) else {
                print("No more books to play in the library.")
                return
            }
                if  Int(nextBook.currentTime) == Int(nextBook.duration){
                    nextBook.currentTime = 0.0
                }
            // Load the next book and update playback
            self.load([nextBook]) { loaded in
                // Notify about the next book
                let userInfo = ["books": [nextBook]]
                NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.bookChange, object: nil, userInfo: userInfo)
                self.audioPlayer?.play()
            }
            
        case .shuffleMode:
            guard var randomBook = getRandomBookFromLibrary() else {
                print("No books available to shuffle.")
                return
            }
                if  Int(randomBook.currentTime) == Int(randomBook.duration){
                    randomBook.currentTime = 0.0
                }
            self.load([randomBook]) { loaded in
                
                let userInfo = ["books": [randomBook]]
                NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.bookChange, object: nil, userInfo: userInfo)
            
                self.audioPlayer?.play()
            }
            
        case .off:
            break
        }
    }
    
    
    func getNextBookInLibrary(after currentBook: Book) -> Book? {
         let library = NewDataMannagerClass.getLibrary()

        var allBooks: [Book] = []
       if let libraryBooks = library.items?.array as? [LibraryItem] {
            
            libraryBooks.forEach { item in
                if let item = item as? Book {
                    allBooks.append( item)
                }else{
                    if let playlist = item as? Playlist {
                        
                        allBooks.append(contentsOf: gatherAllBooks(playlist: playlist))
                        
                    }
                }
            }
           
        }
        
        
        guard let currentIndex = allBooks.firstIndex(of: currentBook) else {
            return nil
        }
        let nextIndex = currentIndex + 1
        return nextIndex < allBooks.count ? allBooks[nextIndex] : nil
    }
    
    func getRandomBookFromLibrary() -> Book? {
   
       let library = NewDataMannagerClass.getLibrary()
        
        var allBooks: [Book] = []
        if let libraryBooks = library.items?.array as? [LibraryItem] {
             
             libraryBooks.forEach { item in
                 if let item = item as? Book {
                     allBooks.append( item)
                 }else{
                     if let playlist = item as? Playlist {
                         
                         allBooks.append(contentsOf: gatherAllBooks(playlist: playlist))
                         
                     }
                 }
             }
            
         }
        
        guard !allBooks.isEmpty else { return nil }
        return allBooks.randomElement()
    }
    
    
    func getPreviousBookInLibrary(before currentBook: Book) -> Book? {
        let library = NewDataMannagerClass.getLibrary()
        var book:Book?
        var allBooks: [Book] = []
        if let libraryItems = library.items?.array as? [LibraryItem] {
            
            libraryItems.forEach { item in
                if let book = item as? Book {
                    allBooks.append(book)
                } else if let playlist = item as? Playlist {
                    allBooks.append(contentsOf: gatherAllBooks(playlist: playlist))
                }
            }
        }
        
   
        guard let currentIndex = allBooks.firstIndex(of: currentBook) else {
            return nil
        }
        let previousIndex = currentIndex - 1
        return previousIndex >= 0 ? allBooks[previousIndex] : nil
    }
    
    func gatherAllBooks(playlist:Playlist) -> [Book] {
       var books = playlist.books?.array as? [Book] ?? []
       
       if let childPlaylists = playlist.children?.allObjects as? [Playlist] {
           for child in childPlaylists {
               books.append(contentsOf: gatherAllBooks(playlist:child))
           }
       }
       return books
   }
    func getbookInLibrary(with identifier: String) -> Book? {
        let library = NewDataMannagerClass.getLibrary()

        var allBooks: [Book] = []
        if let libraryItems = library.items?.array as? [LibraryItem] {
            libraryItems.forEach { item in
                if let book = item as? Book {
                    allBooks.append(book)
                } else if let playlist = item as? Playlist {
                    allBooks.append(contentsOf: gatherAllBooks(playlist: playlist))
                }
            }
        }
      
        let book = allBooks.first { $0.identifier == identifier }

        return book
    }
}
extension PlayerManager {
    
    
    func forwardPressedCostomTime(t:Double) {
        
        
    }
    
    
    func formatTime(_ time:Int) -> String {
        let hours = Int(time / 3600)
        
        let remaining = Float(time - (hours * 3600))
        
        let minutes = Int(remaining / 60)
        
        let seconds = Int(remaining - Float(minutes * 60))
     
        let formattedTime = String(format:"%02d:%02d:%02d",hours, minutes, seconds)
        
        
        return formattedTime
    }
}
extension PlayerManager {
    
    func sleep(in seconds:Int?) {
        UserDefaults.standard.set(seconds, forKey: "sleep_timer")
        
        guard seconds != nil else {
           
            if self.sleepTimer != nil {
                self.sleepTimer.invalidate()
            }
            return
        }
    
        if self.sleepTimer == nil || (self.sleepTimer != nil && !self.sleepTimer.isValid) {
            self.sleepTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateSleepTimer), userInfo: nil, repeats: true)
            RunLoop.main.add(self.sleepTimer, forMode: RunLoop.Mode.common)
        }
    }
    @objc func updateSleepTimer(){
        
        guard PlayerManager.shared.isLoaded else {
          
            if self.sleepTimer != nil {
                self.sleepTimer.invalidate()
            }
            return
        }
        
        let currentTime = UserDefaults.standard.integer(forKey: "sleep_timer")
        
        var newTime:Int? = currentTime - 1
        
        let userInfo = ["time": self.formatTime(newTime!)] as [String : Any]
        NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.sleepTime, object: nil,userInfo: userInfo)
        if newTime == 10 {
            let txt = UserDefaults.standard.object(forKey: "pauseTimeRe") as? String ?? ""
            self.showAlert1(for: "Your player is about to pause.\nReminder : \(txt).")
           
        }
     
        if newTime! <= 0 {
            newTime = nil
          
            if self.sleepTimer != nil && self.sleepTimer.isValid {
                self.sleepTimer.invalidate()
            }
            
            if PlayerManager.shared.isPlaying {
                PlayerManager.shared.pause()
                let userInfo = ["time":"pause"]
                NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.pauseReminder, object: nil,userInfo: userInfo)
            }
        }
        UserDefaults.standard.set(newTime , forKey: "sleep_timer")
    }
    
    public func speedEscalationStart() {
        
        if isPaused{
            if self.EscTimer == nil || (self.EscTimer != nil && !self.EscTimer.isValid) {
                self.EscTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(speedEscalationTimer), userInfo: nil, repeats: true)
                RunLoop.main.add(self.EscTimer, forMode: RunLoop.Mode.common)
            }
        }else{
            
            if self.EscTimer != nil && self.EscTimer.isValid {
                self.EscTimer.invalidate()
            }
        }
    }
    
    public  func speedEscalationStop(){
        
        if self.EscTimer != nil && self.EscTimer.isValid {
            self.EscTimer.invalidate()
        }
    }
    
    @objc func speedEscalationTimer(){
        guard PlayerManager.shared.isLoaded else {
          
            if self.EscTimer != nil {
                self.EscTimer.invalidate()
            }
            return
        }
        if PlayerManager.shared.isPlaying {
            self.incresedSpeed += 1
        }
        
        NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.escTime, object: nil,userInfo: nil)
    }
    
}
extension NSObject {
    func showAlert1(for alert: String) {
        guard let topViewController = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first?.rootViewController?.topmostViewController() else {
            return
        }
        let alertController = UIAlertController(title: nil, message: alert, preferredStyle: UIAlertController.Style.alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(alertAction)
        topViewController.present(alertController, animated: true, completion: nil)
    }
}
