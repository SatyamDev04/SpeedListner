//
//  NewPlayerManagerEngine.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 11/02/26.
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
//
//final class PlayerManager: NSObject {
//
//    static let shared = PlayerManager()
//
//    // MARK: - Audio Engine
//    private let enginePlayer = EngineAudioPlayer.shared
//
//    // MARK: - State
//    private(set) var internalIsPlaying = false
//
//    private var timer: Timer!
//    var sleepTimer: Timer!
//    var EscTimer: Timer!
//
//    // MARK: - Book / Playlist
//    var currentBooks: [Book]?
//    var currentPlayList: Playlist?
//    var currentPlayListIndex: Int?
//    var chapterArray: [Chapter]!
//
//    var rePlaybooks: [Book] = []
//    var playbackMode: PlaybackMode = .off
//
//    var currentBook: Book? {
//        return currentBooks?.first
//    }
//    var email = ""
//    // MARK: - Flags (unchanged)
//    var speedEsalbutton = false
//    var sleepCheck = false
//    var remaingCheck = false
//    var isRecentCheck = false
//    var miniPlayerIsHidden = false
//    var desable_Person = false
//    var isPaused = true
//
//    // MARK: - Speed
//    var incresedSpeed = 1.0
//    var currentSpeed: Float = 1.0
//    var currentUserID: String { return UserDetail.shared.getUserId() }
//    // MARK: - Analytics
//    private var speedTickTimer: Timer?
//    private var lastTickDate: Date?
//
//    // MARK: - Constants
//    private let smartRewindThreshold = 599.0
//    private let maxSmartRewind = 30.0
//
//    private override init() {
//        super.init()
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(engineDidFinish),
//            name: Notification.Name("EnginePlaybackFinished"),
//            object: nil
//        )
//    }
//
//    // MARK: - Computed Properties
//    var isLoaded: Bool {
//        return currentBook != nil
//    }
//
//    var isPlaying: Bool {
//        return internalIsPlaying
//    }
//
//    var duration: TimeInterval {
//        return enginePlayer.duration()
//    }
//
//    var currentTime: TimeInterval {
//        get { enginePlayer.currentTime() }
//        set { currentBook?.currentTime = newValue }
//    }
//
//    // MARK: - LOAD (preserved logic)
//
//
//    func load(_ books: [Book], completion: @escaping (Bool) -> Void) {
//
//        guard let book = books.first else {
//            completion(false)
//            return
//        }
//
//        // Preserve replay logic
//        if rePlaybooks.first?.fileURL == book.fileURL || rePlaybooks.isEmpty {
//            rePlaybooks = books
//        }
//
//        self.currentBooks = books
//        PlayerManager.shared.isRecentCheck = true
//
//        // Keep background thread behavior
//        DispatchQueue.global().async {
//
//            // 🔑 ENGINE LOAD (replaces AVAudioPlayer init)
//            do {
//                try self.enginePlayer.load(url: book.fileURL)
//            } catch {
//                DispatchQueue.main.async {
//                    self.currentBooks = nil
//                    completion(false)
//                }
//                return
//            }
//
//            DispatchQueue.main.async {
//
//                // ---------- NOW PLAYING INFO (UNCHANGED LOGIC) ----------
//                var nowPlayingInfo: [String: Any] = [
//                    MPMediaItemPropertyTitle: book.title ?? "",
//                    MPMediaItemPropertyArtist: book.author ?? "Unknown",
//                    MPMediaItemPropertyPlaybackDuration: self.duration
//                ]
//
//                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
//                    boundsSize: book.artwork.size,
//                    requestHandler: { _ in
//                        return book.artwork
//                    }
//                )
//
//                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
//
//                // ---------- BOOK TIME HANDLING (UNCHANGED) ----------
//                if book.currentTime >= self.duration {
//                    book.currentTime = 0.0
//                }
//
//                if book.currentTime > 0.0 {
//                    self.jumpTo(book.currentTime)
//                }
//
//                // ---------- SPEED (UNCHANGED INTENT) ----------
//                self.enginePlayer.setRate(self.speed)
//
//                // ---------- VOLUME BOOST (UNCHANGED INTENT) ----------
//                self.enginePlayer.setBoost(
//                    enabled: UserDefaults.standard.bool(forKey: "volumeBoostEnabled")
//                )
//
//                // ---------- NOTIFICATION (CRITICAL – KEEP) ----------
//                NotificationCenter.default.post(
//                    name: Notification.Name.AudiobookPlayer.bookReady,
//                    object: nil,
//                    userInfo: ["book": book]
//                )
//
//                completion(true)
//            }
//        }
//    }
//
//    @objc private func engineDidFinish() {
////        stopUpdateTimer()
////        stopAnalyticsTimer()
////
////        internalIsPlaying = false
////        isPaused = true
////
////        MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
////
////        handlePlaybackFinished()
//    }
//
//
////    func load(_ books: [Book], completion: @escaping (Bool) -> Void) {
////
////        guard let book = books.first else {
////            completion(false)
////            return
////        }
////
////        if rePlaybooks.first?.fileURL == book.fileURL || rePlaybooks.isEmpty {
////            rePlaybooks = books
////        }
////
////        currentBooks = books
////
////        do {
////            try enginePlayer.load(url: book.fileURL)
////        } catch {
////            completion(false)
////            return
////        }
////        NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.bookReady, object: nil, userInfo: ["book": book])
////        enginePlayer.setRate(speed)
////        enginePlayer.setBoost(
////            enabled: UserDefaults.standard.bool(forKey: "volumeBoostEnabled")
////        )
////
////        setupNowPlaying(book)
////
////        if book.currentTime >= duration {
////            book.currentTime = 0
////        }
////
////        completion(true)
////    }
//
//    // MARK: - PLAY
////    func play(_ autoplayed: Bool = false) {
////        print("play called")
////        guard let book = currentBook else { return }
////
////        internalIsPlaying = true
////        isPaused = false
////
////        try? AVAudioSession.sharedInstance().setActive(true)
////
////        enginePlayer.play(from: book.currentTime)
////
////        startUpdateTimer()
////        startAnalyticsTimer()
////        updateNowPlayingPlaybackState()
////        MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = 1.0
////        NotificationCenter.default.post(
////            name: Notification.Name.AudiobookPlayer.bookPlayed,
////            object: nil
////        )
////
////    }
//        func play(_ autoplayed: Bool = false) {
//            guard let book = currentBook else { return }
//
//               internalIsPlaying = true
//               isPaused = false
//
//            UserDefaults.standard.set(book.identifier, forKey: UserDefaultsConstants.lastPlayedBook)
//
//            let session = AVAudioSession.sharedInstance()
//               try? session.setCategory(
//                   .playback,
//                   mode: .spokenAudio,
//                   options: [.allowBluetooth, .allowAirPlay]
//               )
//               try? session.setActive(true)
//
//            let completed = Int(duration) == Int(currentTime)
//
//            if autoplayed && completed {
//                return
//            }
//
//            // If book is completed, reset to start
//            if completed {
//                currentTime = 0.0
//            }
//
//            // Handle smart rewind.
//            let lastPauseTimeKey = "\(UserDefaultsConstants.lastPauseTime)_\(book.identifier ?? "")"
//            let smartRewindEnabled = UserDefaults.standard.bool(forKey: UserDefaultsConstants.smartRewindEnabled)
//
//            if smartRewindEnabled, let lastPlayTime: Date = UserDefaults.standard.object(forKey: lastPauseTimeKey) as? Date {
//                let timePassed = Date().timeIntervalSince(lastPlayTime)
//                let timePassedLimited = min(max(timePassed, 0), self.smartRewindThreshold)
//                let delta = timePassedLimited / self.smartRewindThreshold
//
//
//                let rewindTime = pow(delta, 3) * self.maxSmartRewind
//                let newPlayerTime = max(currentTime - rewindTime, 0)
//
//                UserDefaults.standard.set(nil, forKey: lastPauseTimeKey)
//
//                currentTime = newPlayerTime
//            }
//
//
//            if self.timer == nil || (self.timer != nil && !self.timer.isValid) {
//                self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(update), userInfo: nil, repeats: true)
//
//                RunLoop.main.add(self.timer, forMode: RunLoop.Mode.common)
//            }
//
//
//            enginePlayer.play(from: book.currentTime)
//
//                   startUpdateTimer()
//                 startAnalyticsTimer()
//                  updateNowPlayingPlaybackState()
//
//
//            MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyPlaybackRate] = 1.0
//            MPNowPlayingInfoCenter.default().nowPlayingInfo![MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
//
//            DispatchQueue.main.async {
//                NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.bookPlayed, object: nil)
//            }
//
//            self.update()
//        }
//
//
//    // MARK: - PAUSE
//    func pause() {
//        print("pause called")
//
//        guard let book = currentBook else { return }
//        if !internalIsPlaying { return }
//
//        internalIsPlaying = false
//        isPaused = true
//
//        UserDefaults.standard.set(book.identifier, forKey: UserDefaultsConstants.lastPlayedBook)
//
//        book.currentTime = currentTime
//
//        enginePlayer.pause()
//
//        stopUpdateTimer()
//        stopAnalyticsTimer()
//
//        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
//        info[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
//        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
//        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
//
//        UserDefaults.standard.set(Date(),
//            forKey: "\(UserDefaultsConstants.lastPauseTime)_\(book.identifier ?? "")")
//
//        NotificationCenter.default.post(
//            name: Notification.Name.AudiobookPlayer.bookPaused,
//            object: nil
//        )
//    }
//
//
//    // MARK: - PLAY / PAUSE
//    func playPause() {
//        if isPlaying {
//            pause()
//            stopAnalyticsTimer()
//            print("pause called")
//        } else {
//            play()
//            print("play called")
//            startAnalyticsTimer()
//            autoTranscribeIfNeeded(for: currentBook)
//
//        }
//    }
//
//    // MARK: - STOP
//    func stop() {
//        internalIsPlaying = false
//        enginePlayer.stop()
//        stopUpdateTimer()
//        stopAnalyticsTimer()
//    }
//
//    // MARK: - SEEK
//    func jumpTo(_ time: Double) {
//
//        guard let book = currentBook else { return }
//        let clampedTime = min(max(time, 0), duration)
//        book.currentTime = clampedTime
//        enginePlayer.stop()
//        enginePlayer.play(from: clampedTime)
//        internalIsPlaying = true
//        isPaused = false
//    }
//
//    func jumpBy(_ delta: Double) {
//        jumpTo(currentTime + delta)
//    }
//
//    // MARK: - SPEED (preserved)
//    var speed: Float {
//        get {
//            let useGlobal = UserDefaults.standard.bool(
//                forKey: UserDefaultsConstants.globalSpeedEnabled
//            )
//
//            let globalSpeed = UserDefaults.standard.float(forKey: "global_speed")
//            let localSpeed = UserDefaults.standard.float(
//                forKey: (currentBook?.identifier ?? "") + "_speed"
//            )
//
//            let value = useGlobal ? globalSpeed : localSpeed
//            return value > 0 ? value : 1.0
//        }
//        set {
//            guard let book = currentBook else { return }
//
//            UserDefaults.standard.set(
//                newValue,
//                forKey: (book.identifier ?? "") + "_speed"
//            )
//
//            if UserDefaults.standard.bool(
//                forKey: UserDefaultsConstants.globalSpeedEnabled
//            ) {
//                UserDefaults.standard.set(newValue, forKey: "global_speed")
//            }
//
//            enginePlayer.setRate(newValue)
//        }
//    }
//
//    // MARK: - VOLUME BOOST
//    func toggleVolumeBoost(_ enabled: Bool) {
//        UserDefaults.standard.set(enabled, forKey: "volumeBoostEnabled")
//        enginePlayer.setBoost(enabled: enabled)
//    }
//
//    // MARK: - UPDATE TIMER (replacement for delegate)
//    private func startUpdateTimer() {
//        stopUpdateTimer()
//        timer = Timer.scheduledTimer(
//            timeInterval: 1.0,
//            target: self,
//            selector: #selector(update),
//            userInfo: nil,
//            repeats: true
//        )
//        RunLoop.main.add(timer, forMode: .common)
//    }
//
//    private func stopUpdateTimer() {
//        timer?.invalidate()
//        timer = nil
//    }
//
//    @objc private func update() {
//
//        guard let book = currentBook else { return }
//
//        // -------- ENGINE TIME --------
//        book.currentTime = currentTime
//        book.recentPlayTime = Date()
//
//        MPNowPlayingInfoCenter.default().nowPlayingInfo?[
//            MPNowPlayingInfoPropertyElapsedPlaybackTime
//        ] = currentTime
//
//        let isPercentageDifferent =
//            book.percentage != book.percentCompleted ||
//            (book.percentCompleted == 0 && book.progress > 0)
//
//        book.percentCompleted = book.percentage
//        NewDataMannagerClass.saveContext()
//
//        if isPercentageDifferent {
//            NotificationCenter.default.post(
//                name: Notification.Name.AudiobookPlayer.updatePercentage,
//                object: nil,
//                userInfo: [
//                    "progress": book.progress,
//                    "fileURL": book.fileURL
//                ]
//            )
//        }
//
//        NotificationCenter.default.post(
//            name: Notification.Name.AudiobookPlayer.bookPlaying,
//            object: nil,
//            userInfo: [
//                "time": currentTime,
//                "fileURL": book.fileURL
//            ]
//        )
//
//        // -------- END DETECTION (engine replacement) --------
//        if internalIsPlaying && currentTime >= duration - 0.2 {
//
//            internalIsPlaying = false
//            UserDefaults.standard.set(true, forKey: "ask_review")
//
//            handlePlaybackFinished()
//            updateNowPlayingPlaybackState()
//        }
//    }
//    var forwardInterval: TimeInterval {
//        get {
//            if UserDefaults.standard.object(forKey: UserDefaultsConstants.forwardInterval) == nil {
//                return 10.0
//            }
//            return UserDefaults.standard.double(forKey: UserDefaultsConstants.forwardInterval)
//        }
//        set {
//            UserDefaults.standard.set(newValue, forKey: UserDefaultsConstants.forwardInterval)
//
//            MPRemoteCommandCenter.shared()
//                .skipForwardCommand
//                .preferredIntervals = [newValue] as [NSNumber]
//        }
//    }
//
//    var rewindInterval: TimeInterval {
//        get {
//            if UserDefaults.standard.object(forKey: UserDefaultsConstants.rewindInterval) == nil {
//                return 10.0
//            }
//            return UserDefaults.standard.double(forKey: UserDefaultsConstants.rewindInterval)
//        }
//        set {
//            UserDefaults.standard.set(newValue, forKey: UserDefaultsConstants.rewindInterval)
//
//            MPRemoteCommandCenter.shared()
//                .skipBackwardCommand
//                .preferredIntervals = [newValue] as [NSNumber]
//        }
//    }
//
//
//    private func updateNowPlayingPlaybackState() {
//        var info = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
//
//        info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
//
//        //info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
//
//        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
//    }
//
//
//    func forward() {
//        if speed > 1 {
//            let s = Double(speed) * 10
//            jumpBy(s)
//        } else {
//            jumpBy(10)
//        }
//    }
//
//    func rewind() {
//        if speed > 1 {
//            let s = Double(self.speed) * 10
//            self.jumpBy(-s)
//        }else{
//            self.jumpBy(-10)
//        }
//
//    }
//
//    // MARK: - Sleep Timer
//
//    func sleep(in seconds: Int?) {
//
//        UserDefaults.standard.set(seconds, forKey: "sleep_timer")
//
//        // Cancel sleep
//        guard let seconds = seconds else {
//            if sleepTimer != nil {
//                sleepTimer.invalidate()
//                sleepTimer = nil
//            }
//            return
//        }
//
//        // Start timer if not running
//        if sleepTimer == nil || !sleepTimer.isValid {
//            sleepTimer = Timer.scheduledTimer(
//                timeInterval: 1.0,
//                target: self,
//                selector: #selector(updateSleepTimer),
//                userInfo: nil,
//                repeats: true
//            )
//            RunLoop.main.add(sleepTimer, forMode: .common)
//        }
//    }
//
//    @objc func updateSleepTimer(){
//
//        guard PlayerManager.shared.isLoaded else {
//
//            if self.sleepTimer != nil {
//                self.sleepTimer.invalidate()
//            }
//            return
//        }
//
//        let currentTime = UserDefaults.standard.integer(forKey: "sleep_timer")
//
//        var newTime:Int? = currentTime - 1
//
//        let userInfo = ["time": self.formatTime(newTime!)] as [String : Any]
//        NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.sleepTime, object: nil,userInfo: userInfo)
//        if newTime == 10 {
//            let txt = UserDefaults.standard.object(forKey: "pauseTimeRe") as? String ?? ""
//            self.showAlert1(for: "Your player is about to pause.\nReminder : \(txt).")
//
//        }
//
//        if newTime! <= 0 {
//            newTime = nil
//
//            if self.sleepTimer != nil && self.sleepTimer.isValid {
//                self.sleepTimer.invalidate()
//            }
//
//            if PlayerManager.shared.isPlaying {
//                PlayerManager.shared.pause()
//                PlayerManager.shared.sleepCheck = false
//                let userInfo = ["time":"pause"]
//                NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.pauseReminder, object: nil,userInfo: userInfo)
//            }
//        }
//        UserDefaults.standard.set(newTime , forKey: "sleep_timer")
//    }
//
//    func formatTime(_ time:Int) -> String {
//        let hours = Int(time / 3600)
//
//        let remaining = Float(time - (hours * 3600))
//
//        let minutes = Int(remaining / 60)
//
//        let seconds = Int(remaining - Float(minutes * 60))
//
//        let formattedTime = String(format:"%02d:%02d:%02d",hours, minutes, seconds)
//
//
//        return formattedTime
//    }
//
//
//    // MARK: - END HANDLER (delegate replacement)
//    private func handlePlaybackFinished() {
//
//        NotificationCenter.default.post(
//            name: Notification.Name.AudiobookPlayer.bookEnd,
//            object: nil
//        )
//
//        switch playbackMode {
//
//        case .repeatMode:
//            currentBook?.currentTime = 0
//            play()
//
//        case .linearMode:
//            if let next = getNextBookInLibrary(after: currentBook!) {
//                load([next]) { _ in self.play() }
//            }
//
//        case .shuffleMode:
//            if let random = getRandomBookFromLibrary() {
//                load([random]) { _ in self.play() }
//            }
//
//        case .off:
//            break
//        }
//    }
//
//    // MARK: - ANALYTICS (unchanged)
//    private func startAnalyticsTimer() {
//        stopAnalyticsTimer()
//        lastTickDate = Date()
//        speedTickTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in }
//        RunLoop.main.add(speedTickTimer!, forMode: .common)
//    }
//
//    private func stopAnalyticsTimer() {
//        speedTickTimer?.invalidate()
//        speedTickTimer = nil
//        lastTickDate = nil
//    }
//
//    // MARK: - NOW PLAYING
//    private func setupNowPlaying(_ book: Book) {
//        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
//            MPMediaItemPropertyTitle: book.title ?? "",
//            MPMediaItemPropertyArtist: book.author ?? "",
//            MPMediaItemPropertyPlaybackDuration: duration
//        ]
//    }
//
//    func getNextBookInLibrary(after currentBook: Book) -> Book? {
//        let library = NewDataMannagerClass.getLibrary()
//
//        var allBooks: [Book] = []
//        if let libraryBooks = library.items?.array as? [LibraryItem] {
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
//
//    func getRandomBookFromLibrary() -> Book? {
//
//        let library = NewDataMannagerClass.getLibrary()
//
//        var allBooks: [Book] = []
//        if let libraryBooks = library.items?.array as? [LibraryItem] {
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
//        guard !allBooks.isEmpty else { return nil }
//        return allBooks.randomElement()
//    }
//
//
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
//
//    func gatherAllBooks(playlist:Playlist) -> [Book] {
//        var books = playlist.books?.array as? [Book] ?? []
//
//        if let childPlaylists = playlist.children?.allObjects as? [Playlist] {
//            for child in childPlaylists {
//                books.append(contentsOf: gatherAllBooks(playlist:child))
//            }
//        }
//        return books
//    }
//    func getbookInLibrary(with identifier: String) -> Book? {
//        let library = NewDataMannagerClass.getLibrary()
//
//        var allBooks: [Book] = []
//        if let libraryItems = library.items?.array as? [LibraryItem] {
//            libraryItems.forEach { item in
//                if let book = item as? Book {
//                    allBooks.append(book)
//                } else if let playlist = item as? Playlist {
//                    allBooks.append(contentsOf: gatherAllBooks(playlist: playlist))
//                }
//            }
//        }
//
//        let book = allBooks.first { $0.identifier == identifier }
//
//        return book
//    }
//    func forwardPressedCostomTime(t:Double) {
//
//
//    }
//
//    public func speedEscalationStart() {
//
//        if isPaused{
//            if self.EscTimer == nil || (self.EscTimer != nil && !self.EscTimer.isValid) {
//                self.EscTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(speedEscalationTimer), userInfo: nil, repeats: true)
//                RunLoop.main.add(self.EscTimer, forMode: RunLoop.Mode.common)
//            }
//        }else{
//
//            if self.EscTimer != nil && self.EscTimer.isValid {
//                self.EscTimer.invalidate()
//            }
//        }
//    }
//
//    @objc func speedEscalationTimer(){
//        guard PlayerManager.shared.isLoaded else {
//
//            if self.EscTimer != nil {
//                self.EscTimer.invalidate()
//            }
//            return
//        }
//        if PlayerManager.shared.isPlaying {
//            self.incresedSpeed += 1
//        }
//
//        NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.escTime, object: nil,userInfo: nil)
//    }
//
//    public  func speedEscalationStop(){
//        if self.EscTimer != nil && self.EscTimer.isValid {
//            self.EscTimer.invalidate()
//        }
//    }
//
//    public func nextChapter(after chapter: Chapter) -> Chapter? {
//        guard !self.chapterArray.isEmpty else {
//            return nil
//        }
//
//        if chapter == self.chapterArray.last { return nil }
//
//        return self.chapterArray[Int(chapter.index)]
//    }
//    public func previousChapter(after chapter: Chapter) -> Chapter? {
//
//
//        guard !self.chapterArray.isEmpty else { return nil }
//        let idx = Int(chapter.index) - 1
//        guard idx > 0 else { return nil }   // no previous if at index 0
//        return self.chapterArray[idx - 1]
//    }
//
//    func autoTranscribeIfNeeded(for book: Book?) {
//        guard let book = book,
//              UserDefaults.standard.bool(forKey: "autoTranscribeWhileListening") else { return }
//
//        AudioMonitorManager.shared.startTranscribeAllBookmarksInBackground(book: book)
//    }
//}

