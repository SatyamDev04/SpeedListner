//
//  SpeedListerAttributes.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 26/08/25.
//


import ActivityKit

struct SpeedListerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var title: String
        var isPlaying: Bool
        var currentTime: Double
        var duration: Double
    }
    var bookID: String
}
