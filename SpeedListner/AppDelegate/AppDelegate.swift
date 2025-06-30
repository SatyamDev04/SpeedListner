//
//  AppDelegate.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 09/09/24.
//

import UIKit
import CoreData
import AVFoundation
import UserNotifications
import MediaPlayer

var pUrl:URL?

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var backgroundCompletionHandler: (() -> Void)?
    
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
          
          backgroundCompletionHandler = completionHandler
      }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
       
        let defaults:UserDefaults = UserDefaults.standard
        UNUserNotificationCenter.current().delegate = self
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (granted, error) in
                    if granted {
                        print("User gave permissions for local notifications")
                    }
                }
        // Perfrom first launch setup
        if !defaults.bool(forKey: UserDefaultsConstants.completedFirstLaunch) {
            // Set default settings
            defaults.set(true, forKey: UserDefaultsConstants.smartRewindEnabled)
            
            defaults.set(true, forKey: UserDefaultsConstants.completedFirstLaunch)
        }
        
        UIApplication.shared.statusBarStyle = .lightContent
        
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.spokenAudio, options: [])

        // register to audio-interruption notifications
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleAudioInterruptions(_:)), name: AVAudioSession.interruptionNotification, object: nil)

        // register to audio-route-change notifications
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleAudioRouteChange(_:)), name: AVAudioSession.routeChangeNotification, object: nil)
        
        //clean leftover sleep timer registry
        UserDefaults.standard.set(nil, forKey: "sleep_timer")
        setupMPRemoteCommands()
       

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

        // Pause playback if route changes due to a disconnect
        switch reason {
        case .oldDeviceUnavailable:
            PlayerManager.shared.pause()
        default:
            break
        }
    }
    func setupMPRemoteCommands() {
        // Play / Pause
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().togglePlayPauseCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            PlayerManager.shared.playPause()
            return .success
        }

        MPRemoteCommandCenter.shared().playCommand.isEnabled = true
        MPRemoteCommandCenter.shared().playCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            PlayerManager.shared.play()
            return .success
        }

        MPRemoteCommandCenter.shared().pauseCommand.isEnabled = true
        MPRemoteCommandCenter.shared().pauseCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            PlayerManager.shared.pause()
            return .success
        }

        // Forward
        MPRemoteCommandCenter.shared().skipForwardCommand.preferredIntervals = [NSNumber(value: PlayerManager.shared.forwardInterval)]

        MPRemoteCommandCenter.shared().skipForwardCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            PlayerManager.shared.forward()
            return .success
        }

        MPRemoteCommandCenter.shared().nextTrackCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            PlayerManager.shared.forward()
            return .success
        }

        MPRemoteCommandCenter.shared().seekForwardCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
            guard let cmd = commandEvent as? MPSeekCommandEvent, cmd.type == .endSeeking else {
                return .success
            }

            // End seeking
            PlayerManager.shared.forward()
            return .success
        }

        // Rewind
        MPRemoteCommandCenter.shared().skipBackwardCommand.preferredIntervals = [NSNumber(value: PlayerManager.shared.rewindInterval)]

        MPRemoteCommandCenter.shared().skipBackwardCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            PlayerManager.shared.rewind()
            return .success
        }

        MPRemoteCommandCenter.shared().previousTrackCommand.addTarget { (_) -> MPRemoteCommandHandlerStatus in
            PlayerManager.shared.rewind()
            return .success
        }

        MPRemoteCommandCenter.shared().seekBackwardCommand.addTarget { (commandEvent) -> MPRemoteCommandHandlerStatus in
            guard let cmd = commandEvent as? MPSeekCommandEvent, cmd.type == .endSeeking else {
                return .success
            }

            // End seeking
            PlayerManager.shared.rewind()
            return .success
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

