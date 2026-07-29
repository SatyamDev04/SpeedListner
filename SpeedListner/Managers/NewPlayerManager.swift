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

//enum PlaybackMode {
//    case repeatMode
//    case linearMode
//    case shuffleMode
//    case off
//}

enum PlaybackMode {
    case repeatAll
    case repeatOne
    case linear
    case shuffle
    case off
}

class PlayerManager: NSObject {
    
    static let shared = PlayerManager()
    
    var audioPlayer: AVAudioPlayer?
    private var playerItem: AVPlayerItem!
    var speedEsalbutton = false {
        didSet {
            UserDefaults.standard.set(speedEsalbutton, forKey: UserDefaultsConstants.speedEscalationEnabled)
        }
    }
    var currentSpeed:Float = 1.0
    var currentBooks: [Book]?
    var currentPlayList:Playlist?
    var currentPlayListIndex:Int?
    var chapterArray: [Chapter]!
    var sleepCheck = false
    var remaingCheck = false {
        didSet {
            UserDefaults.standard.set(remaingCheck, forKey: UserDefaultsConstants.showRemainingTime)
        }
    }
    var isRecentCheck = false
    var incresedSpeed = 1.0
    var miniPlayerIsHidden = false
    var desable_Person:Bool = false
    var playbackMode: PlaybackMode = .linear
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
    
    //    18 march 26
    var playbackQueue: [Book] = []
    var currentIndex: Int = 0
    
    // 599 = 10 mins
    private let smartRewindThreshold = 599.0
    private let maxSmartRewind = 30.0
    var currentUserID: String { return UserDetail.shared.getUserId() }
    var isSwitchingTrack = false
    // MARK: - Analytics timer (for average speed)
    private var speedTickTimer: Timer?
    private var lastTickDate: Date?

    override private init() {
        super.init()
        restoreTogglePreferences()
    }

    private func restoreTogglePreferences() {
        let defaults = UserDefaults.standard

        if defaults.object(forKey: UserDefaultsConstants.speedEscalationEnabled) != nil {
            speedEsalbutton = defaults.bool(forKey: UserDefaultsConstants.speedEscalationEnabled)
        }

        if defaults.object(forKey: UserDefaultsConstants.showRemainingTime) != nil {
            remaingCheck = defaults.bool(forKey: UserDefaultsConstants.showRemainingTime)
        }
    }
    
    
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
        self.currentIndex = self.playbackQueue.firstIndex(of: book) ?? 0
        DispatchQueue.global().async {
            
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
            //            if UserDefaults.standard.bool(forKey: UserDefaultsConstants.boostVolumeEnabled) {
            //                audioplayer.volume = 2.0
            //            }
            let isBoostEnabled = UserDefaults.standard.bool(forKey: "volumeBoostEnabled")
            
            if isBoostEnabled {
                audioplayer.volume = 2.0
            } else {
                audioplayer.volume = 0.6   // base lower volume
            }
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
                if #available(iOS 16.1, *) {
                    //                    LiveActivityManager.start(
                    //                        bookID: book.identifier ?? "",
                    //                        title: book.title ?? "Unknown",
                    //                        duration: book.duration,
                    //                        isPlaying: self.isPlaying,
                    //                        currentTime: self.currentTime
                    //                    )
                } else {
                    // Fallback on earlier versions
                }
                
                
                if book.currentTime >= audioplayer.duration {
                    book.currentTime = 0.0
                    audioplayer.currentTime = 0.0
                }
                if book.currentTime > 0.0 {
                    self.jumpTo(book.currentTime)
                }
                
                
                audioplayer.rate = self.speed
                
                NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.bookReady, object: nil, userInfo: ["book": book])
                
                completion(true)
            })
            print(book.fileURL,"ja kark")
            
        }
    }
    
    private func startAnalyticsTimer() {
        // Avoid multiple timers
        if speedTickTimer != nil { return }
        lastTickDate = Date()
        speedTickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tickSpeedAnalytics()
        }
        RunLoop.main.add(speedTickTimer!, forMode: .common)
    }
    
    // Call this from your existing pause/stop code
    private func stopAnalyticsTimer() {
        speedTickTimer?.invalidate()
        speedTickTimer = nil
        lastTickDate = nil
    }
    private func tickSpeedAnalytics() {
        guard let last = lastTickDate else {
            lastTickDate = Date()
            return
        }
        let now = Date()
        var delta = now.timeIntervalSince(last)
        // clamp to avoid spikes if app lags
        delta = max(0, min(delta, 5))
        lastTickDate = now
        
        // Only count time while actually playing
        if audioPlayer?.isPlaying == true {
            let rateToRecord = Double(speed)
            let category: String? = {
                guard let bookId = currentBook?.identifier else { return nil }
                return SpeedTrackCategoryManager.shared.category(forBookId: bookId)
            }()
            SpeedAnalyticsManager.shared.recordTick(
                userID: currentUserID,
                rate: Float(rateToRecord),
                delta: delta,
                category: category
            )
        }
    }
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
            
            UserDefaults.standard.set(true, forKey: "ask_review")
            
            // ❗ Only post bookEnd if NOT repeating forever
            if playbackMode != .repeatOne {
                NotificationCenter.default.post(
                    name: Notification.Name.AudiobookPlayer.bookEnd,
                    object: nil
                )
            }
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
        startAnalyticsTimer()
        
        
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
        stopAnalyticsTimer()
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
            stopAnalyticsTimer()
        } else {
            self.play()
            guard let currentBook = self.currentBook else {
                print("No current book available.")
                return
            }
            autoTranscribeIfNeeded(for: currentBook)
            startAnalyticsTimer()
        }
    }
    
    func stop() {
        self.audioPlayer?.stop()
        
        
        audioPlayer?.stop()
        
        stopAnalyticsTimer()
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
    //comented on 18 march 2025
    //    public func nextChapter(after chapter: Chapter) -> Chapter? {
    //        guard !self.chapterArray.isEmpty else {
    //            return nil
    //        }
    //
    //        if chapter == self.chapterArray.last { return nil }
    //
    //        return self.chapterArray[Int(chapter.index)]
    //    }
    
    public func nextChapter(after chapter: Chapter) -> Chapter? {
        guard !self.chapterArray.isEmpty else {
            return nil
        }
        print(chapter.start, "chapter.start",chapter.index)
        if chapter == self.chapterArray.last { return nil }
        
        return self.chapterArray[Int(chapter.index + 1)]
    }
    
    public func previousChapter(after chapter: Chapter) -> Chapter? {
        //        guard !self.chapterArray.isEmpty else {
        //            return nil
        //        }
        //
        //        if chapter == self.chapterArray.first { return nil }
        //
        //        return self.chapterArray[Int(chapter.index ) - 2]
        
        guard !self.chapterArray.isEmpty else { return nil }
        let idx = Int(chapter.index)
        guard idx > 0 else { return nil }   // no previous if at index 0
        return self.chapterArray[idx - 1]
    }
    
    func autoTranscribeIfNeeded(for book: Book?) {
        guard let book = book,
              UserDefaults.standard.bool(forKey: "autoTranscribeWhileListening") else { return }
        
        AudioMonitorManager.shared.startTranscribeAllBookmarksInBackground(book: book)
    }
}



extension PlayerManager: AVAudioPlayerDelegate {
    // Leave the slider at max
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {

        guard flag else { return }

     
        if isSwitchingTrack && (playbackMode == .repeatAll || playbackMode == .shuffle) {
            print("Skipping duplicate trigger")
            return
        }

        UserDefaults.standard.removeObject(forKey: UserDefaultsConstants.lastPlayedBook)

        self.update()

        guard let currentBook = self.currentBook else {
            return
        }

        switch playbackMode {

        case .repeatOne:
            isSwitchingTrack = true
            player.currentTime = 0
            self.play()

        case .repeatAll:
            isSwitchingTrack = true

            if let next = nextBookInQueue() {
                currentIndex += 1
                loadNext(next)
            } else {
                currentIndex = 0

                for book in playbackQueue {
                    resetIfCompleted(book)
                }

                NewDataMannagerClass.saveContext()

                if let first = playbackQueue.first {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        self.loadNext(first)
                    }
                }
            }

        case .linear:
            if let next = nextBookInQueue() {
                currentIndex += 1
                loadNext(next)
            } else {
                // Keep linear playback scoped to the active queue/folder context.
                // Do not jump to next playlist or full library automatically.
                print("End of current queue")
            }

        case .shuffle:
            isSwitchingTrack = true

            guard !playbackQueue.isEmpty else { return }

            if playbackQueue.count == 1 {
                currentIndex = 0
                loadNext(playbackQueue[0])
                return
            }

            var nextIndex: Int
            repeat {
                nextIndex = Int.random(in: 0..<playbackQueue.count)
            } while nextIndex == currentIndex

            currentIndex = nextIndex
            loadNext(playbackQueue[currentIndex])

        case .off:
            break
        }

        autoTranscribeIfNeeded(for: currentBook)
    }
    
    // Added on 18 march 26
    func nextBookInQueue() -> Book? {
        let nextIndex = currentIndex + 1
        return nextIndex < playbackQueue.count ? playbackQueue[nextIndex] : nil
    }
    
    func previousBookInQueue() -> Book? {
        let prevIndex = currentIndex - 1
        return prevIndex >= 0 ? playbackQueue[prevIndex] : nil
    }

    static func randomCandidateIndices(
        queueCount: Int,
        excluding currentIndex: Int
    ) -> [Int] {
        guard queueCount > 1 else { return [] }
        return (0..<queueCount).filter { $0 != currentIndex }
    }

    /// Immediately starts a different random book. The current queue is preferred;
    /// when it only contains the current book, the full library becomes the queue.
    func playRandomBook(completion: ((Bool) -> Void)? = nil) {
        guard !isSwitchingTrack else {
            completion?(false)
            return
        }

        playbackMode = .shuffle
        prepareQueueForRandomPlayback()

        guard !playbackQueue.isEmpty else {
            completion?(false)
            return
        }

        if let currentBook,
           let queueIndex = playbackQueue.firstIndex(of: currentBook) {
            currentIndex = queueIndex
        } else {
            currentIndex = min(max(currentIndex, 0), playbackQueue.count - 1)
        }

        let candidateIndices = Self.randomCandidateIndices(
            queueCount: playbackQueue.count,
            excluding: currentIndex
        ).filter {
            FileManager.default.fileExists(atPath: playbackQueue[$0].fileURL.path)
        }

        guard let randomIndex = candidateIndices.randomElement() else {
            completion?(false)
            return
        }

        isSwitchingTrack = true
        currentIndex = randomIndex
        loadNext(playbackQueue[randomIndex], completion: completion)
    }

    private func prepareQueueForRandomPlayback() {
        guard playbackQueue.count <= 1 else { return }

        let library = NewDataMannagerClass.getLibrary()
        let libraryItems = library.items?.array as? [LibraryItem] ?? []
        var books: [Book] = []

        for item in libraryItems {
            if let book = item as? Book {
                books.append(book)
            } else if let playlist = item as? Playlist {
                books.append(contentsOf: getAllBooks(from: playlist))
            }
        }

        var seenPaths = Set<String>()
        let uniqueBooks = books.filter { book in
            seenPaths.insert(book.fileURL.standardizedFileURL.path).inserted
        }

        if !uniqueBooks.isEmpty {
            playbackQueue = sortBooksAsPerUserPreference(uniqueBooks)
        }
    }
    
    func loadNext(_ book: Book, completion: ((Bool) -> Void)? = nil) {
        self.audioPlayer?.stop()
        self.audioPlayer = nil
        resetIfCompleted(book)
        self.load([book]) { loaded in
            guard loaded else {
                self.isSwitchingTrack = false
                completion?(false)
                return
            }

            NotificationCenter.default.post(
                name: Notification.Name.AudiobookPlayer.bookChange,
                object: nil,
                userInfo: ["books": [book]]
            )
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.audioPlayer?.currentTime = book.currentTime
                self.play()
                self.isSwitchingTrack = false
                completion?(true)
            }
        }
    }
    
    func resetIfCompleted(_ book: Book) {
        let safeThreshold = book.duration - 0.5
        
        if book.currentTime >= safeThreshold {
            book.currentTime = 0.0
        }
    }
    
    func getNextPlaylist(after current: Playlist) -> Playlist? {
        
        let library = NewDataMannagerClass.getLibrary()
        
        let playlists = (library.items?.array as? [LibraryItem])?
            .compactMap { $0 as? Playlist } ?? []
        
        guard let index = playlists.firstIndex(of: current) else { return nil }
        
        let nextIndex = index + 1
        
        return nextIndex < playlists.count ? playlists[nextIndex] : nil
    }
    
    func getFirstBook(from playlist: Playlist) -> Book? {
        return (playlist.books?.array as? [Book])?.first
    }
    
    func getAllLibraryBooks() -> [Book] {
        return getAllBooks(from: NewDataMannagerClass.getLibrary())
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
    
    func sortBooksAsPerUserPreference(_ books: [Book]) -> [Book] {

        switch UserDetail.shared.getSortBy() {

        case "0": // Newest Upload
            return books.sorted {
                ($0.uploadTime ?? Date.distantPast) >
                ($1.uploadTime ?? Date.distantPast)
            }

        case "1": // Oldest Upload
            return books.sorted {
                ($0.uploadTime ?? Date.distantPast) <
                ($1.uploadTime ?? Date.distantPast)
            }

        case "2": // Recently Played
            return books.sorted {
                ($0.recentPlayTime ?? Date.distantPast) >
                ($1.recentPlayTime ?? Date.distantPast)
            }

        case "3": // Alphabetical
            return books.sorted {
                ($0.title ?? "")
                    .localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
            }

        default:
            return books
        }
    }
    // commented on 18 march 26
    //switch playbackMode {
    // case .repeatMode:
    
    //                player.stop()
    //player.currentTime = 0
    
    
    // let userInfo = ["books": self.rePlaybooks]
    // NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.bookChange, object: nil, userInfo: userInfo)
    //   DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
    //       self.play()
    //   self.update()
    // Start playback again
    
    
    //  }
    //case .linearMode:
    //    guard let currentBook = self.currentBook else {
    //        print("No current book available.")
    //        return
    //    }
    //
    //    guard var nextBook = getNextBookInLibrary(after: currentBook) else {
    //        print("No more books to play in the library.")
    //        return
    //    }
    //        if  Int(nextBook.currentTime) == Int(nextBook.duration){
    //            nextBook.currentTime = 0.0
    //        }
    //    // Load the next book and update playback
    //    self.load([nextBook]) { loaded in
    //        // Notify about the next book
    //        let userInfo = ["books": [nextBook]]
    //        NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.bookChange, object: nil, userInfo: userInfo)
    //        self.audioPlayer?.play()
    //    }
    //
    //case .shuffleMode:
    //    guard var randomBook = getRandomBookFromLibrary() else {
    //        print("No books available to shuffle.")
    //        return
    //    }
    //        if  Int(randomBook.currentTime) == Int(randomBook.duration){
    //            randomBook.currentTime = 0.0
    //        }
    //    self.load([randomBook]) { loaded in
    //
    //        let userInfo = ["books": [randomBook]]
    //        NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.bookChange, object: nil, userInfo: userInfo)
    //
    //        self.audioPlayer?.play()
    //    }
    //
    //case .off:
    //    break
    //}
    //    func getNextBookInLibrary(after currentBook: Book) -> Book? {
    //         let library = NewDataMannagerClass.getLibrary()
    //
    //        var allBooks: [Book] = []
    //       if let libraryBooks = library.items?.array as? [LibraryItem] {
    //
    //            libraryBooks.forEach { item in
    //                if let item = item as? Book {
    //                    allBooks.append( item)
    //                }else{
    //                    if let playlist = item as? Playlist {
    //
    //                        allBooks.append(contentsOf: gatherAllBooks(playlist: playlist))
    //
    //                    }
    //                }
    //            }
    //
    //        }
    //
    //
    //        guard let currentIndex = allBooks.firstIndex(of: currentBook) else {
    //            return nil
    //        }
    //        let nextIndex = currentIndex + 1
    //        return nextIndex < allBooks.count ? allBooks[nextIndex] : nil
    //    }
    
    //    func getRandomBookFromLibrary() -> Book? {
    //
    //       let library = NewDataMannagerClass.getLibrary()
    //
    //        var allBooks: [Book] = []
    //        if let libraryBooks = library.items?.array as? [LibraryItem] {
    //
    //             libraryBooks.forEach { item in
    //                 if let item = item as? Book {
    //                     allBooks.append( item)
    //                 }else{
    //                     if let playlist = item as? Playlist {
    //
    //                         allBooks.append(contentsOf: gatherAllBooks(playlist: playlist))
    //
    //                     }
    //                 }
    //             }
    //
    //         }
    //
    //        guard !allBooks.isEmpty else { return nil }
    //        return allBooks.randomElement()
    //    }
    
    
    //    func getPreviousBookInLibrary(before currentBook: Book) -> Book? {
    //        let library = NewDataMannagerClass.getLibrary()
    //        var book:Book?
    //        var allBooks: [Book] = []
    //        if let libraryItems = library.items?.array as? [LibraryItem] {
    //
    //            libraryItems.forEach { item in
    //                if let book = item as? Book {
    //                    allBooks.append(book)
    //                } else if let playlist = item as? Playlist {
    //                    allBooks.append(contentsOf: gatherAllBooks(playlist: playlist))
    //                }
    //            }
    //        }
    //
    //
    //        guard let currentIndex = allBooks.firstIndex(of: currentBook) else {
    //            return nil
    //        }
    //        let previousIndex = currentIndex - 1
    //        return previousIndex >= 0 ? allBooks[previousIndex] : nil
    //    }
    
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
                PlayerManager.shared.sleepCheck = false
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
    
    func toggleVolumeBoost(_ enabled: Bool) {
        
        UserDefaults.standard.set(enabled, forKey: "volumeBoostEnabled")
        
        guard let player = self.audioPlayer else { return }
        
        if enabled {
            player.volume = 2.0   // max possible loud
        } else {
            player.volume = 0.6   // base volume
        }
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
