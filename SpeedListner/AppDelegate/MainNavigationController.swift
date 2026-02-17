//
//  MainNavigationController.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 12/02/26.
//


import UIKit

class MainNavigationController: UINavigationController {

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        switch AppOrientationManager.shared.current {
        case .normal:
            return .allButUpsideDown
        case .lockVertical:
            return .portrait
        case .lockHorizontal:
            return .landscape
        }
    }

    override var shouldAutorotate: Bool {
        return true
    }
}