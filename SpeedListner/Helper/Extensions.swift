//
//  Extensions.swift
//  SpeedListner
//
//Created by Satyam Dwivedi on 16/06/23.
//

import UIKit
import DeckTransition

extension UIViewController {
    func showAlert(_ title: String?, message: String?, style: UIAlertController.Style) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        let okButton = UIAlertAction(title: "Ok", style: .default, handler: nil)
        
        alert.addAction(okButton)
        
        alert.popoverPresentationController?.sourceView = self.view
        alert.popoverPresentationController?.sourceRect = CGRect(x: Double(self.view.bounds.size.width / 2.0), y: Double(self.view.bounds.size.height-45), width: 1.0, height: 1.0)
        
        self.present(alert, animated: true, completion: nil)
    }
    
    //utility function to transform seconds to format HH:MM:SS
    func formatTime(_ time:Int) -> String {
        var hours = Int(time / 3600)
        
        let remaining = Float(time - (hours * 3600))
        
        let minutes = Int(remaining / 60)
        
        let seconds = Int(remaining - Float(minutes * 60))
//        if hours < 0 {
//            hours = 00
//        }
        
        var formattedTime = String(format:"%02d:%02d:%02d",hours, minutes, seconds)

          
        return formattedTime
    }
    func formatTime2(_ time: TimeInterval) -> String {
        let durationFormatter = DateComponentsFormatter()

        durationFormatter.unitsStyle = .positional
        durationFormatter.allowedUnits = [ .minute, .second ]
        durationFormatter.zeroFormattingBehavior = .pad
        durationFormatter.collapsesLargestUnit = false

        if time > 3599.0 {
            durationFormatter.allowedUnits = [ .hour, .minute, .second ]
        }

        return durationFormatter.string(from: time)!
    }
    func formatSpeed(_ speed: Float) -> String {
        return (speed.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(speed))" : "\(speed)") + "x"
    }
    func formatDuration(_ duration: TimeInterval, unitsStyle: DateComponentsFormatter.UnitsStyle = .short) -> String {
        let durationFormatter = DateComponentsFormatter()

        durationFormatter.unitsStyle = unitsStyle
        durationFormatter.allowedUnits = [ .minute, .second ]
        durationFormatter.collapsesLargestUnit = true

        return durationFormatter.string(from: duration)!
    }
    
    func presentModal(_ viewController:UIViewController, animated:Bool, completion: (() -> Swift.Void)? = nil){
        let transitionDelegate = DeckTransitioningDelegate()
        viewController.transitioningDelegate = transitionDelegate
        viewController.modalPresentationStyle = .custom
        self.present(viewController, animated: animated, completion: completion)
    }
}

extension UINavigationController {
    override open var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}

extension Notification.Name {
    
    public struct AudiobookPlayer {
        public static let bookPlayed = Notification.Name(rawValue: "com.book.play")
        public static let libraryOpenURL = Notification.Name(rawValue: "com.openurl")
        public static let libraryOpenURL1 = Notification.Name(rawValue: "com.library.openurl1")
        public static let playlistOpenURL = Notification.Name(rawValue: "com.playlist.openurl")
        public static let subPlaylistOpenURL = Notification.Name(rawValue: "com.subPlaylist.openurl")
        public static let childsubPlaylistOpenURL = Notification.Name(rawValue: "com.childsubPlaylist.openurl")
        public static let openURL = Notification.Name(rawValue: "com.openURL")
        public static let isBook = Notification.Name(rawValue: "com.isBook")
        public static let requestReview = Notification.Name(rawValue: "com.requestreview")
        public static let updateTimer = Notification.Name(rawValue: "com.book.timer")
        public static let sleepTime = Notification.Name(rawValue: "com.book.sleepTime")
        public static let escTime = Notification.Name(rawValue: "com.book.escTime")
        public static let pauseReminder = Notification.Name(rawValue: "com.book.pauseReminder")
        public static let updatePercentage = Notification.Name(rawValue: "com.book.percentage")
        public static let updateListOfFiles = Notification.Name(rawValue: "com.book.updateListOfFiles")
        public static let updateChapter = Notification.Name(rawValue: "com.book.chapter")
        public static let errorLoadingBook = Notification.Name(rawValue: "com.book.error")
        public static let bookReady = Notification.Name(rawValue: "com.book.ready")
        public static let play_pause = Notification.Name(rawValue: "com.book.play_pause")
        public static let playBook = Notification.Name(rawValue: "com.book.play")
        public static let bookEnd = Notification.Name(rawValue: "com.book.end")
        public static let newPlayListAdded = Notification.Name(rawValue: "com.newPlayList")
        public static let bookPaused = Notification.Name(rawValue: "com.book.pause")
        public static let bookStopped = Notification.Name(rawValue: "com.book.stop")
        
        public static let bookChange = Notification.Name(rawValue: "com.book.change")
        public static let bookPlaying = Notification.Name(rawValue: "com.book.playback")
        public static let skipIntervalsChange = Notification.Name(rawValue: "com.settings.skip")
        public static let reloadData = Notification.Name(rawValue: "com.reloaddata")
        public static let playerPresented = Notification.Name(rawValue: "com.player.presented")
        public static let playerDismissed = Notification.Name(rawValue: "com.player.dismissed")
    }
}
extension UITextView {

    private class PlaceholderLabel: UILabel { }

    private var placeholderLabel: PlaceholderLabel {
        if let label = subviews.compactMap( { $0 as? PlaceholderLabel }).first {
            return label
        } else {
            let label = PlaceholderLabel(frame: .zero)
            label.font = font
            addSubview(label)
            return label
        }
    }

    @IBInspectable
    var placeholder: String {
        get {
            return subviews.compactMap( { $0 as? PlaceholderLabel }).first?.text ?? ""
        }
        set {
            let placeholderLabel = self.placeholderLabel
            placeholderLabel.text = newValue
            placeholderLabel.numberOfLines = 0
            let width = frame.width - textContainer.lineFragmentPadding * 2
            let size = placeholderLabel.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
            placeholderLabel.frame.size.height = size.height
            placeholderLabel.frame.size.width = width
            placeholderLabel.frame.origin = CGPoint(x: textContainer.lineFragmentPadding, y: textContainerInset.top)

            textStorage.delegate = self
        }
    }

}

extension UITextView: NSTextStorageDelegate {

    public func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorage.EditActions, range editedRange: NSRange, changeInLength delta: Int) {
        if editedMask.contains(.editedCharacters) {
            placeholderLabel.isHidden = !text.isEmpty
        }
    }

}
