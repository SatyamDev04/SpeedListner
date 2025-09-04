//
//  SpeedAnalyticsManager.swift
//  SpeedListner
//
//  Created by YATIN  KALRA on 28/08/25.
//


import Foundation

final class SpeedAnalyticsManager {
    static let shared = SpeedAnalyticsManager()
    private init() {}

    // MARK: - Storage Model
    struct Totals: Codable {
        var totalSeconds: TimeInterval = 0         // Σ Δt while playing
        var weightedRateSeconds: Double = 0        // Σ (rate * Δt)
        var updatedAt: Date = Date()
    }

    // Optional daily buckets if you want last 7 days, etc.
    struct DailyBucket: Codable {
        var totalSeconds: TimeInterval = 0
        var weightedRateSeconds: Double = 0
    }

    private func keyAllTime(userID: String) -> String { "speed_totals_alltime_\(userID)" }
    private func keyDaily(userID: String) -> String { "speed_totals_daily_\(userID)" } // [String: DailyBucket], key=yyyy-MM-dd

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Public API

    /// Call every tick while *playing* with the current playback `rate` and `delta` seconds since last tick.
    func recordTick(userID: String, rate: Float, delta: TimeInterval) {
        guard delta > 0, rate > 0 else { return }

        // All-time
        var totals = loadTotals(userID: userID)
        totals.totalSeconds += delta
        totals.weightedRateSeconds += Double(rate) * delta
        totals.updatedAt = Date()
        saveTotals(userID: userID, totals: totals)

        // Daily bucket (optional)
        var daily = loadDaily(userID: userID)
        let dayKey = Self.dayKey(for: Date())
        var today = daily[dayKey] ?? DailyBucket()
        today.totalSeconds += delta
        today.weightedRateSeconds += Double(rate) * delta
        daily[dayKey] = today
        saveDaily(userID: userID, daily: daily)
    }

    /// Reset for a user (e.g., logout).
    func reset(userID: String) {
        UserDefaults.standard.removeObject(forKey: keyAllTime(userID: userID))
        UserDefaults.standard.removeObject(forKey: keyDaily(userID: userID))
    }

    /// All-time average speed for user (returns nil if no listening yet).
    func averageAllTime(userID: String) -> Double? {
        let totals = loadTotals(userID: userID)
        guard totals.totalSeconds > 0 else { return nil }
        return totals.weightedRateSeconds / totals.totalSeconds
    }

    /// Average speed for the last N days (inclusive of today). Returns nil if no data.
    func averageForLastDays(userID: String, days: Int) -> Double? {
        guard days > 0 else { return averageAllTime(userID: userID) }
        let daily = loadDaily(userID: userID)
        let keys = (0..<days).map { offset -> String in
            let date = Calendar.current.date(byAdding: .day, value: -offset, to: Date())!
            return Self.dayKey(for: date)
        }
        var total: TimeInterval = 0
        var weighted: Double = 0
        for k in keys {
            if let b = daily[k] {
                total += b.totalSeconds
                weighted += b.weightedRateSeconds
            }
        }
        guard total > 0 else { return nil }
        return weighted / total
    }

    // MARK: - Persistence
    private func loadTotals(userID: String) -> Totals {
        guard let data = UserDefaults.standard.data(forKey: keyAllTime(userID: userID)),
              let t = try? decoder.decode(Totals.self, from: data) else {
            return Totals()
        }
        return t
    }

    private func saveTotals(userID: String, totals: Totals) {
        if let data = try? encoder.encode(totals) {
            UserDefaults.standard.set(data, forKey: keyAllTime(userID: userID))
        }
    }

    private func loadDaily(userID: String) -> [String: DailyBucket] {
        guard let data = UserDefaults.standard.data(forKey: keyDaily(userID: userID)),
              let m = try? decoder.decode([String: DailyBucket].self, from: data) else {
            return [:]
        }
        return m
    }

    private func saveDaily(userID: String, daily: [String: DailyBucket]) {
        if let data = try? encoder.encode(daily) {
            UserDefaults.standard.set(data, forKey: keyDaily(userID: userID))
        }
    }

    private static func dayKey(for date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = .init(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
extension SpeedAnalyticsManager {

    // MARK: - Public series APIs

    /// Last `days` daily buckets (default 30). Each item: (date, avgSpeed?, totalSeconds)
    func dailySeries(userID: String, days: Int = 30) -> [(date: Date, avg: Double?, seconds: TimeInterval)] {
        let daily = loadDaily(userID: userID)
        var out: [(Date, Double?, TimeInterval)] = []
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())

        for offset in stride(from: days - 1, through: 0, by: -1) {
            guard let d = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let key = Self.dayKey(for: d)
            if let b = daily[key], b.totalSeconds > 0 {
                out.append((d, b.weightedRateSeconds / b.totalSeconds, b.totalSeconds))
            } else {
                out.append((d, nil, 0))
            }
        }
        return out
    }

    /// Last `months` calendar months (default 12). Each item: (startOfMonth, avgSpeed?, totalSeconds)
    func monthlySeries(userID: String, months: Int = 12) -> [(monthStart: Date, avg: Double?, seconds: TimeInterval)] {
        let daily = loadDaily(userID: userID)
        var out: [(Date, Double?, TimeInterval)] = []
        let cal = Calendar(identifier: .gregorian)
        let now = Date()

        // Build from oldest → newest
        guard let startOfThisMonth = cal.date(from: cal.dateComponents([.year, .month], from: now)) else { return out }
        for m in stride(from: months - 1, through: 0, by: -1) {
            guard let monthStart = cal.date(byAdding: .month, value: -m, to: startOfThisMonth) else { continue }
            guard let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart) else { continue }

            var total: TimeInterval = 0
            var weighted: Double = 0

            var day = monthStart
            while day < min(nextMonth, now) {
                let key = Self.dayKey(for: day)
                if let b = daily[key] {
                    total += b.totalSeconds
                    weighted += b.weightedRateSeconds
                }
                guard let nd = cal.date(byAdding: .day, value: 1, to: day) else { break }
                day = nd
            }

            if total > 0 {
                out.append((monthStart, weighted / total, total))
            } else {
                out.append((monthStart, nil, 0))
            }
        }
        return out
    }
}
