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

    // Call this at app start (AppDelegate or SceneDelegate)
    func startObserving() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(deviceOrientationChanged),
                                               name: UIDevice.orientationDidChangeNotification,
                                               object: nil)
        // Ensure device notifications are enabled
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()

        // Check initial orientation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.checkAndPresentIfNeeded()
        }
    }

    // Call this on app shutdown / deinit if needed
    func stopObserving() {
        NotificationCenter.default.removeObserver(self)
        UIDevice.current.endGeneratingDeviceOrientationNotifications()
    }

    @objc private func deviceOrientationChanged() {
        DispatchQueue.main.async {
            self.checkAndPresentIfNeeded()
        }
    }

    private func checkAndPresentIfNeeded() {
        let orientation = UIDevice.current.orientation
        // treat .landscapeLeft, .landscapeRight as landscape
        let isLandscape = orientation == .landscapeLeft || orientation == .landscapeRight

        if isLandscape {
            presentLandscape()
        } else {
            dismissLandscape()
        }
    }

    private func topMostViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }),
              let root = keyWindow.rootViewController else {
            return nil
        }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }

    private func presentLandscape() {
        guard !isPresented else { return }
        guard let top = topMostViewController() else { return }

        // instantiate VC
        let vc = LandscapePlayerViewController()
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle = .crossDissolve

        // Present over top most VC
        top.present(vc, animated: true) {
            self.isPresented = true
            self.presentedVC = vc
        }
    }

    private func dismissLandscape() {
        guard isPresented, let presented = self.presentedVC else { return }
        presented.dismiss(animated: true) {
            self.isPresented = false
            self.presentedVC = nil
        }
    }
}
