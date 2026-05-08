//
//  UIViewController+Extension.swift
//  SpeedListners
//
//  Created by ravi on 15/09/22.
//

import Foundation
import UIKit

extension UIViewController {
    
    func removeChild() {
        self.children.forEach {
            $0.willMove(toParent: nil)
            $0.view.removeFromSuperview()
            $0.removeFromParent()
        }
    }
    
    
    // status bar customize
    func setStatusBarStyle(_ style: UIStatusBarStyle) {
        if let statusBar = UIApplication.shared.value(forKey: "statusBar") as? UIView {
            statusBar.backgroundColor = style == .lightContent ? UIColor.black : .white
//            statusBar.setValue(style == .lightContent ? ColorCompatibility.label : ColorCompatibility.systemBackground, forKey: "foregroundColor")
        }
    }
    
    func setUpStatusBar(_ color : UIColor) {
        if #available(iOS 13.0, *) {
            let app = UIApplication.shared
            let statusBarHeight: CGFloat = app.statusBarFrame.size.height
            
            let statusbarView = UIView()
            statusbarView.backgroundColor = color
            view.addSubview(statusbarView)
            
            statusbarView.translatesAutoresizingMaskIntoConstraints = false
            statusbarView.heightAnchor
                .constraint(equalToConstant: statusBarHeight).isActive = true
            statusbarView.widthAnchor
                .constraint(equalTo: view.widthAnchor, multiplier: 1.0).isActive = true
            statusbarView.topAnchor
                .constraint(equalTo: view.topAnchor).isActive = true
            statusbarView.centerXAnchor
                .constraint(equalTo: view.centerXAnchor).isActive = true
            
        } else {
            
//            let statusBar = UIApplication.shared.value(forKeyPath: "statusBarWindow.statusBar") as? UIView
//            statusBar?.backgroundColor = color
//            statusBar?.alpha = 0.5

        }
    }
    
    func showAlert(for alert: String) {
        let alertController = UIAlertController(title: nil, message: alert, preferredStyle: UIAlertController.Style.alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(alertAction)
        present(alertController, animated: true, completion: nil)
    }
    
    
    static let DELAY_SHORT = 1.5
      static let DELAY_LONG = 2.0

      func showToast(_ text: String, delay: TimeInterval = DELAY_LONG) {
          let label = ToastLabel()
          label.backgroundColor = UIColor(red:70/255, green:0/255, blue:100/255, alpha: 0.7)
        
          label.textColor = .white
          label.textAlignment = .center
          label.font = UIFont.systemFont(ofSize: 15)
          label.alpha = 0
          label.text = text
          label.clipsToBounds = true
          label.layer.cornerRadius = 20
          label.numberOfLines = 0
          label.textInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
          label.translatesAutoresizingMaskIntoConstraints = false
          view.addSubview(label)

          let saveArea = view.safeAreaLayoutGuide
          label.centerXAnchor.constraint(equalTo: saveArea.centerXAnchor, constant: 0).isActive = true
          label.leadingAnchor.constraint(greaterThanOrEqualTo: saveArea.leadingAnchor, constant: 15).isActive = true
          label.trailingAnchor.constraint(lessThanOrEqualTo: saveArea.trailingAnchor, constant: -15).isActive = true
          label.bottomAnchor.constraint(equalTo: saveArea.bottomAnchor, constant: -30).isActive = true

          UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseIn, animations: {
              label.alpha = 1
          }, completion: { _ in
              UIView.animate(withDuration: 0.5, delay: delay, options: .curveEaseOut, animations: {
                  label.alpha = 0
              }, completion: {_ in
                  label.removeFromSuperview()
              })
          })
      }

    func showSpeedTrackTopBadge() {
        let badgeTag = 909001
        view.viewWithTag(badgeTag)?.removeFromSuperview()
        let currentUID = UserDetail.shared.getUserId()
        let uid = currentUID.isEmpty ? UserDetail.shared.getPreviousUserId() : currentUID
        guard !uid.isEmpty else { return }

        let thl = SpeedAnalyticsManager.shared.totalHoursListened(userID: uid)
        let streak = SpeedAnalyticsManager.shared.currentStreak(userID: uid)

        let badge = UIView()
        badge.tag = badgeTag
        badge.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        badge.layer.cornerRadius = 8
        badge.clipsToBounds = true
        badge.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        iconView.image = UIImage(named: "streak") ?? UIImage(systemName: "flame.fill")
        iconView.tintColor = .white
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.required, for: .horizontal)
        iconView.widthAnchor.constraint(equalToConstant: 14).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 14).isActive = true

        let streakLabel = UILabel()
        streakLabel.numberOfLines = 1
        streakLabel.textAlignment = .left
        streakLabel.font = .systemFont(ofSize: 11, weight: .bold)
        streakLabel.textColor = .white
        streakLabel.text = "\(streak)"

        let thlLabel = UILabel()
        thlLabel.numberOfLines = 1
        thlLabel.textAlignment = .left
        thlLabel.font = .systemFont(ofSize: 11, weight: .bold)
        thlLabel.textColor = .white
        thlLabel.text = "THL: \(formatTHL(thl))"

        let streakRow = UIStackView(arrangedSubviews: [iconView, streakLabel])
        streakRow.axis = .horizontal
        streakRow.alignment = .center
        streakRow.spacing = 4

        let mainStack = UIStackView(arrangedSubviews: [streakRow, thlLabel])
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.axis = .vertical
        mainStack.alignment = .leading
        mainStack.spacing = 1

        badge.addSubview(mainStack)
        view.addSubview(badge)

        let hasBackButton = (navigationItem.leftBarButtonItem != nil) || (navigationController?.viewControllers.first != self)
        let leadingOffset: CGFloat = hasBackButton ? 44 : 8

        NSLayoutConstraint.activate([
            badge.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: leadingOffset),
            badge.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 6),
            badge.widthAnchor.constraint(greaterThanOrEqualToConstant: 88),
            mainStack.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 6),
            mainStack.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -6),
            mainStack.topAnchor.constraint(equalTo: badge.topAnchor, constant: 4),
            mainStack.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -4)
        ])
    }

    private func formatTHL(_ hours: Double) -> String {
        let wholeHours = max(0, Int(hours.rounded(.down)))
        return "\(wholeHours) THL"
    }

    func ensureCategoryAssigned(for book: Book, completion: @escaping () -> Void) {
        guard let identifier = book.identifier, !identifier.isEmpty else {
            completion()
            return
        }

        if SpeedTrackCategoryManager.shared.category(forBookId: identifier) != nil {
            completion()
            return
        }

        let primary = SpeedTrackCategoryManager.shared.primaryLabel()
        let secondary = SpeedTrackCategoryManager.shared.secondaryLabel()

        let alert = UIAlertController(
            title: "Categorize Audiobook",
            message: "Choose a category for \"\(book.title ?? "this book")\".",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: primary, style: .default, handler: { _ in
            SpeedTrackCategoryManager.shared.setCategory("fiction", forBookId: identifier)
            completion()
        }))
        alert.addAction(UIAlertAction(title: secondary, style: .default, handler: { _ in
            SpeedTrackCategoryManager.shared.setCategory("non-fiction", forBookId: identifier)
            completion()
        }))
        alert.addAction(UIAlertAction(title: "Skip", style: .cancel, handler: { _ in
            completion()
        }))
        present(alert, animated: true)
    }
}

class ToastLabel: UILabel {
    var textInsets = UIEdgeInsets.zero {
        didSet { invalidateIntrinsicContentSize() }
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetRect = bounds.inset(by: textInsets)
        let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
        let invertedInsets = UIEdgeInsets(top: -textInsets.top, left: -textInsets.left, bottom: -textInsets.bottom, right: -textInsets.right)

        return textRect.inset(by: invertedInsets)
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: textInsets))
    }
}
@IBDesignable
public class Gradient: UIView {
    @IBInspectable var startColor:   UIColor = .black { didSet { updateColors() }}
    @IBInspectable var endColor:     UIColor = .white { didSet { updateColors() }}
    @IBInspectable var startLocation: Double =   0.05 { didSet { updateLocations() }}
    @IBInspectable var endLocation:   Double =   0.95 { didSet { updateLocations() }}
    @IBInspectable var horizontalMode:  Bool =  false { didSet { updatePoints() }}
    @IBInspectable var diagonalMode:    Bool =  false { didSet { updatePoints() }}

    override public class var layerClass: AnyClass { CAGradientLayer.self }

    var gradientLayer: CAGradientLayer { layer as! CAGradientLayer }

    func updatePoints() {
        if horizontalMode {
            gradientLayer.startPoint = diagonalMode ? .init(x: 1, y: 0) : .init(x: 0, y: 0.5)
            gradientLayer.endPoint   = diagonalMode ? .init(x: 0, y: 1) : .init(x: 1, y: 0.5)
        } else {
            gradientLayer.startPoint = diagonalMode ? .init(x: 0, y: 0) : .init(x: 0.5, y: 0)
            gradientLayer.endPoint   = diagonalMode ? .init(x: 1, y: 1) : .init(x: 0.5, y: 1)
        }
    }
    func updateLocations() {
        gradientLayer.locations = [startLocation as NSNumber, endLocation as NSNumber]
    }
    func updateColors() {
        gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
    }
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updatePoints()
        updateLocations()
        updateColors()
    }
}
