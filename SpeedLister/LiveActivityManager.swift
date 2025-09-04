//
//  LiveActivityManager.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 26/08/25.
//




import ActivityKit

@available(iOS 16.1, *)
class LiveActivityManager {
    static var current: Activity<SpeedListerAttributes>?

    static func start(bookID: String, title: String, duration: Double, isPlaying: Bool, currentTime: Double) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let attributes = SpeedListerAttributes(bookID: bookID)
        let state = SpeedListerAttributes.ContentState(
            title: title,
            isPlaying: isPlaying,
            currentTime: currentTime,
            duration: duration
        )

        do {
            current = try Activity.request(
                attributes: attributes,
                contentState: state
            )
        } catch {
            print("❌ Failed to start Live Activity: \(error)")
        }
    }

    static func update(title: String, isPlaying: Bool, currentTime: Double, duration: Double) {
        let state = SpeedListerAttributes.ContentState(
            title: title,
            isPlaying: isPlaying,
            currentTime: currentTime,
            duration: duration
        )
        Task {
            await current?.update(using: state)
        }
    }

    static func end() {
        Task {
            await current?.end(dismissalPolicy: .immediate)
        }
    }
}

