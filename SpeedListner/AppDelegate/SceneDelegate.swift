//
//  SceneDelegate.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 09/09/24.
//




import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var pUrl: URL?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        print("[SceneDelegate] App is connecting to the scene.")

        // Handle incoming URL if the app is opened via a file
        if let url = connectionOptions.urlContexts.first?.url {
            print("[SceneDelegate] Received file URL in willConnectTo: \(url)")
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.handleIncomingAudioFile(at: url)
            }
        } else {
            print("[SceneDelegate] No file URL received in willConnectTo.")
        }

        guard let _ = (scene as? UIWindowScene) else { return }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        print("[SceneDelegate] App received URL while running.")
        
        if let url = URLContexts.first?.url {
            print("[SceneDelegate] Received file URL in openURLContexts: \(url)")
            handleIncomingAudioFile(at: url)
        } else {
            print("[SceneDelegate] No file URL received in openURLContexts.")
        }
    }

    private func handleIncomingAudioFile(at url: URL) {
        print("[SceneDelegate] Handling file at URL: \(url)")

        // Check if the file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            print("[SceneDelegate] File does not exist at path: \(url.path)")
            showAlert(title: "Error", message: "File does not exist at path: \(url.path)")
            return
        }

        do {
            let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(url.lastPathComponent)

            // Remove any existing file at the destination
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                print("[SceneDelegate] File already exists at destination. Removing old file.")
                try FileManager.default.removeItem(at: destinationURL)
            }

            // Copy the file to the temporary directory
            print("[SceneDelegate] Copying file to: \(destinationURL)")
            try FileManager.default.copyItem(at: url, to: destinationURL)

            print("[SceneDelegate] File successfully copied to: \(destinationURL)")
          //  showAlert(title: "Success", message: "File successfully copied to: \(destinationURL)")

            // Post a notification with the new file URL
            let userInfo = ["fileURL": destinationURL]
            NotificationCenter.default.post(name: Notification.Name.AudiobookPlayer.libraryOpenURL, object: nil, userInfo: userInfo)
            pUrl = destinationURL
        } catch {
            print("[SceneDelegate] Failed to copy file: \(error.localizedDescription)")
            showAlert(title: "Error", message: "Failed to copy file: \(error.localizedDescription)")
        }
    }

    private func showAlert(title: String, message: String) {
        guard let topViewController = getTopViewController() else { return }
      
        DispatchQueue.main.async {
            topViewController.showToast(message)
        }
    }

    private func getTopViewController(base: UIViewController? = UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController) -> UIViewController? {
        if let navController = base as? UINavigationController {
            return getTopViewController(base: navController.visibleViewController)
        } else if let tabBarController = base as? UITabBarController,
                  let selected = tabBarController.selectedViewController {
            return getTopViewController(base: selected)
        } else if let presented = base?.presentedViewController {
            return getTopViewController(base: presented)
        }
        return base
    }
}
