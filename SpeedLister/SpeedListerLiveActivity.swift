//
//  SpeedListerLiveActivity.swift
//  SpeedLister
//
//  Created by YATIN  KALRA on 26/08/25.
//



import ActivityKit
import WidgetKit
import SwiftUI

struct SpeedListerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SpeedListerAttributes.self) { context in
            // LOCK SCREEN UI
            VStack {
                Text(context.state.title)
                    .font(.headline)
                ProgressView(value: context.state.currentTime, total: context.state.duration)
                HStack {
                    Button(intent: Rewind10Intent()) { Image(systemName: "gobackward.10") }
                    Button(intent: TogglePlayPauseIntent()) {
                        Image(systemName: context.state.isPlaying ? "pause.fill" : "play.fill")
                    }
                    Button(intent: Forward10Intent()) { Image(systemName: "goforward.10") }
                    Button(intent: AddBookmarkIntent()) { Image(systemName: "bookmark.fill") }
                }
            }
        } dynamicIsland: { context in
            // Can leave empty if you don’t want Dynamic Island
            DynamicIsland {
                DynamicIslandExpandedRegion(.center) { EmptyView() }
            } compactLeading: { EmptyView() }
              compactTrailing: { EmptyView() }
              minimal: { EmptyView() }
        }
    }
}




