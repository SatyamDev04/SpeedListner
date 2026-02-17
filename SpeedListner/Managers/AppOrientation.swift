//
//  AppOrientation.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 11/02/26.
//

import UIKit


final class AppOrientationManager {

    static let shared = AppOrientationManager()

    enum OrientationMode {
        case normal
        case lockVertical
        case lockHorizontal
    }

    var current: OrientationMode = .normal
    
    
    func applyOrientation(_ mode: OrientationMode) {

        current = mode

        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }

        switch mode {
        case .normal:
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .allButUpsideDown))
        case .lockVertical:
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .portrait))
        case .lockHorizontal:
            scene.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
        }

        UIViewController.attemptRotationToDeviceOrientation()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            LandscapePlayerManager.shared.forceCheck()
        }
    }
}

