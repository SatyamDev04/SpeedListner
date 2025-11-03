//
//  LandscapePlayerManager.swift
//  SpeedListner
//
//  Created by satyam dwivedi on 31/10/25.
//

import UIKit

final class LandscapePlayerManager {
    static let shared = LandscapePlayerManager()
    private init() {}

    private var isPresented = false
    private weak var presentedVC: UIViewController?

    // MARK: - Start / Stop observing
    func startObserving() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceOrientationChanged),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(sceneDidBecomeActive),
                                               name: UIScene.didActivateNotification,
                                               object: nil)

        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.checkAndPresentIfNeeded()
        }
    }

    func stopObserving() {
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    @objc private func deviceOrientationChanged() {
        DispatchQueue.main.async {
            self.checkAndPresentIfNeeded()
        }
    }

    @objc private func sceneDidBecomeActive() {
        DispatchQueue.main.async {
            self.checkAndPresentIfNeeded()
        }
    }

    // MARK: - Determine interface orientation reliably
    private func isAppInterfaceLandscape() -> Bool {
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive || $0.activationState == .foregroundInactive }) {
            return windowScene.interfaceOrientation.isLandscape
        }

        if let keyWindow = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
            return keyWindow.bounds.width > keyWindow.bounds.height
        }

        let d = UIDevice.current.orientation
        return d == .landscapeLeft || d == .landscapeRight
    }

    // MARK: - Present/dismiss logic (robust)
    private func checkAndPresentIfNeeded() {
        let shouldBeLandscape = isAppInterfaceLandscape()

        if shouldBeLandscape {
            presentLandscapeIfNeeded()
        } else {
            // Try to dismiss landscape even if other modals are on top.
            dismissLandscapeIfNeededCompletely()
        }
    }

    private func topMostViewController() -> UIViewController? {
        // Find key window's root VC and drill down to topmost.
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
           let root = keyWindow.rootViewController {
            var top = root
            while let presented = top.presentedViewController {
                top = presented
            }
            return top
        }

        // Fallback to UIApplication delegate window (older iOS)
        if let window = (UIApplication.shared.delegate as? UIApplicationDelegate)?.window, let root = window as? UIWindow, let rootVC = root.rootViewController {
            var top = rootVC
            while let presented = top.presentedViewController {
                top = presented
            }
            return top
        }

        return nil
    }

    private func presentLandscapeIfNeeded() {
        guard !isPresented else { return }
        guard let top = topMostViewController() else { return }

        // instantiate and present
        let story = UIStoryboard(name: "Main", bundle: nil)
                let vc = story.instantiateViewController(withIdentifier: "LandscapePlayerViewController") as! LandscapePlayerViewController
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve

        DispatchQueue.main.async {
            // guard again in case of race
            guard !self.isPresented else { return }
            top.present(vc, animated: true) {
                self.isPresented = true
                self.presentedVC = vc
            }
        }
    }

    /// Try to dismiss the landscape controller even if there are other view controllers stacked on top.
    /// This method will attempt to peel off presented view controllers from the top until the landscape VC
    /// is dismissed. It uses a short async loop (completion handlers and DispatchQueue) to avoid presenting/dismissing while another transition is in progress.
    private func dismissLandscapeIfNeededCompletely() {
        DispatchQueue.main.async {
            // If we don't have any landscape presented, nothing to do
            guard self.isPresented, let landscape = self.presentedVC else {
                self.isPresented = false
                self.presentedVC = nil
                return
            }

            // Find the top-most VC in the app
            guard let top = self.topMostViewController() else {
                // if we can't find a top, still attempt to dismiss the known landscape VC directly
                self.dismissVCIfNeeded(landscape)
                return
            }

            // If the top-most is the landscape VC itself -> dismiss it directly
            if top === landscape {
                self.dismissVCIfNeeded(landscape)
                return
            }

            // Otherwise, top is some other modal over the landscape VC. We need to dismiss the top-most
            // and then re-run the dismiss flow to clear the stack down to the landscape VC.
            // We'll dismiss recursively with a small completion handler to ensure animated transitions finish.
            self.dismissTopMostThenContinue()
        }
    }

    /// Dismiss the current top-most VC, then re-run the landscape dismiss flow. This avoids trying to dismiss non-top controllers.
    private func dismissTopMostThenContinue() {
        guard let top = topMostViewController() else {
            // nothing to dismiss; try to dismiss landscape directly
            if let landscape = self.presentedVC {
                self.dismissVCIfNeeded(landscape)
            }
            return
        }

        // If top is the landscape VC, dismiss it and finish
        if let landscape = self.presentedVC, top === landscape {
            self.dismissVCIfNeeded(landscape)
            return
        }

        // Otherwise dismiss the top-most presented VC (the overlay), then try again.
        top.dismiss(animated: true) {
            // small delay to let the animation finish and the VC hierarchy update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                // If landscape VC still present, attempt to remove more layers until it's gone
                if self.presentedVC != nil {
                    self.dismissLandscapeIfNeededCompletely()
                } else {
                    self.isPresented = false
                }
            }
        }
    }

    /// Dismiss a specific VC (if presented) and update flags.
    private func dismissVCIfNeeded(_ vc: UIViewController) {
        // If vc is not in view hierarchy or already dismissed, just clear flags
        guard let top = self.topMostViewController() else {
            // safe cleanup
            self.isPresented = false
            self.presentedVC = nil
            return
        }

        // If the topmost is the same VC, dismiss it
        if top === vc {
            top.dismiss(animated: true) {
                self.isPresented = false
                self.presentedVC = nil
            }
            return
        }

        // If the topmost is not vc, there may be other modals; attempt to dismiss topmost first
        // then call dismissLandscapeIfNeededCompletely which will loop.
        self.dismissTopMostThenContinue()
    }
}
