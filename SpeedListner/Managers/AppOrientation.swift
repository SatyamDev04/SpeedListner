//
//  AppOrientation.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 11/02/26.
//


import UIKit

enum AppOrientation: String {
    case normal
    case lockVertical
    case lockHorizontal
}

final class AppOrientationManager {

    static let shared = AppOrientationManager()

    private let key = "AppOrientationSetting"

    var current: AppOrientation {
        get {
            if let value = UserDefaults.standard.string(forKey: key),
               let orientation = AppOrientation(rawValue: value) {
                return orientation
            }
            return .normal
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
            applyOrientation(newValue)
        }
    }

    func applyOrientation(_ orientation: AppOrientation) {
        switch orientation {
        case .normal:
            UIDevice.current.setValue(UIInterfaceOrientation.unknown.rawValue, forKey: "orientation")
        case .lockVertical:
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        case .lockHorizontal:
            UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
        }

        UINavigationController.attemptRotationToDeviceOrientation()
    }
}