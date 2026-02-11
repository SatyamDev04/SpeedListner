//
//  AppDelegate.swift
//  SpeedListner
//  Created by YATIN  KALRA on 09/09/24.
//

import UIKit
import CoreData
import AVFoundation
import UserNotifications
import MediaPlayer
import IQKeyboardManager
 var pUrl:URL?

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var backgroundCompletionHandler: (() -> Void)?
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
          
          backgroundCompletionHandler = completionHandler
      }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
     
        IQKeyboardManager.shared().isEnabled = true
        let defaults:UserDefaults = UserDefaults.standard
        UNUserNotificationCenter.current().delegate = self
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                    if granted {
                        print("User gave permissions for local notifications")
                    }
                }
  
        if !defaults.bool(forKey: UserDefaultsConstants.completedFirstLaunch) {
           
            defaults.set(true, forKey: UserDefaultsConstants.smartRewindEnabled)
            
            defaults.set(true, forKey: UserDefaultsConstants.completedFirstLaunch)
        }
    
        UIApplication.shared.statusBarStyle = .lightContent
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.spokenAudio, options: [.allowAirPlay, .allowBluetooth])

    
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleAudioInterruptions(_:)), name: AVAudioSession.interruptionNotification, object: nil)

       
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleAudioRouteChange(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
        
        //clean leftover sleep timer registry
        UserDefaults.standard.set(nil, forKey: "sleep_timer")
        setupMPRemoteCommands()
        Thread.sleep(forTimeInterval: 2.5)
        LandscapePlayerManager.shared.startObserving()
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        //print("Received audio file URL: \(url)")
        handleIncomingAudioFile(at: url)
           return true
       }
       
    private func handleIncomingAudioFile(at url: URL) {
      
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
            // Call the completion handler if it exists
        guard let navigationVC = UIApplication.shared.keyWindow?.rootViewController!,
              navigationVC.children.count > 1 else{
            return
        }

        }
    
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
    
    }

    @objc(userNotificationCenter:willPresentNotification:withCompletionHandler:) func userNotificationCenter(_ center: UNUserNotificationCenter,
              willPresent notification: UNNotification,
              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void)  {
           completionHandler(.alert)
       }
    
    @objc func handleAudioInterruptions(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }

        switch type {
        case .began:
            if PlayerManager.shared.isPlaying {
                PlayerManager.shared.pause()
            }
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else {
                return
            }

            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                PlayerManager.shared.play()
            }
        }
    }
    
    @objc func handleAudioRouteChange(_ notification: Notification) {
        guard PlayerManager.shared.isPlaying,
            let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                return
        }

       
        switch reason {
        case .oldDeviceUnavailable:
            PlayerManager.shared.pause()
        default:
            break
        }
    }
 

    func setupMPRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
    
        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            PlayerManager.shared.playPause()
            return .success
        }

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            PlayerManager.shared.play()
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            PlayerManager.shared.pause()
            return .success
        }

        
        commandCenter.skipForwardCommand.preferredIntervals = [NSNumber(value: PlayerManager.shared.forwardInterval)]
        commandCenter.skipForwardCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            PlayerManager.shared.forward()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            PlayerManager.shared.forward()
            return .success
        }

        commandCenter.seekForwardCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
            guard let cmd = commandEvent as? MPSeekCommandEvent, cmd.type == .endSeeking else {
                return .success
            }
            PlayerManager.shared.forward()
            return .success
        }

        
        commandCenter.skipBackwardCommand.preferredIntervals = [NSNumber(value: PlayerManager.shared.rewindInterval)]
        
        commandCenter.skipBackwardCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            PlayerManager.shared.rewind()
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            PlayerManager.shared.rewind()
            return .success
        }

        commandCenter.seekBackwardCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
            guard let cmd = commandEvent as? MPSeekCommandEvent, cmd.type == .endSeeking else {
                return .success
            }
            PlayerManager.shared.rewind()
            return .success
        }

        commandCenter.bookmarkCommand.isEnabled = true
        commandCenter.likeCommand.localizedTitle = "Bookmark"
        commandCenter.likeCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            print("Bookmark button pressed from lock screen")
            guard let book = PlayerManager.shared.currentBook else {
                return .success
            }
            BookmarkManager.shared.saveWithoutNote(book: book ) { success in
                if success {
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                    self.showBookmarkFeedback()
                    print("Bookmark saved successfully")
                } else {
                    print("Failed to save bookmark")
                }
            }
            return .success
        }
    }

    
    func showBookmarkFeedback() {
        
        let content = UNMutableNotificationContent()
        content.title = "Bookmark Added"
        content.body = "Your bookmark was saved successfully."

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
        var nowPlaying = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]

        // Save original subtitle
        let originalSubtitle = nowPlaying[MPMediaItemPropertyAlbumTitle]

        // Show feedback
        nowPlaying[MPMediaItemPropertyAlbumTitle] = "🔖 Bookmark added"
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlaying

        // Revert after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            var reverted = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
            reverted[MPMediaItemPropertyAlbumTitle] = originalSubtitle
            MPNowPlayingInfoCenter.default().nowPlayingInfo = reverted
        }
    }
    private func showAlert(title: String, message: String) {
        guard let window = window else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))

        DispatchQueue.main.async {
            window.rootViewController?.present(alert, animated: true, completion: nil)
        }
    }
}

