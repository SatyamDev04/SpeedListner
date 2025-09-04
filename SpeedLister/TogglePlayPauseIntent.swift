//
//  TogglePlayPauseIntent.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 26/08/25.
//


import AppIntents

struct TogglePlayPauseIntent: AppIntent {
    static var title: LocalizedStringResource = "Play/Pause"

    func perform() async throws -> some IntentResult {
        await MainActor.run {
//            PlayerManager.shared.playPause()
        }
        return .result()
    }
}

struct Forward10Intent: AppIntent {
    static var title: LocalizedStringResource = "Forward 10"

    func perform() async throws -> some IntentResult {
        await MainActor.run {
//            PlayerManager.shared.forward()
        }
        return .result()
    }
}

struct Rewind10Intent: AppIntent {
    static var title: LocalizedStringResource = "Rewind 10"

    func perform() async throws -> some IntentResult {
        await MainActor.run {
//            PlayerManager.shared.rewind()
        }
        return .result()
    }
}

struct AddBookmarkIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Bookmark"

    func perform() async throws -> some IntentResult {
        await MainActor.run {
//            BookMarkVC.addBookmarkFromLiveActivity()
        }
        return .result()
    }
}
