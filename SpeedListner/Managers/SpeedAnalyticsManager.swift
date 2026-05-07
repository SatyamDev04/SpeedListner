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
        var longestStreakDays: Int = 0
        var currentStreakDays: Int = 0
        var lastQualifiedDayKey: String?
        var first3MRAS: Double?
        var updatedAt: Date = Date()
    }

    // Optional daily buckets if you want last 7 days, etc.
    struct DailyBucket: Codable {
        var totalSeconds: TimeInterval = 0
        var weightedRateSeconds: Double = 0
        var fictionSeconds: TimeInterval = 0
        var nonFictionSeconds: TimeInterval = 0
        var fictionWeightedRateSeconds: Double = 0
        var nonFictionWeightedRateSeconds: Double = 0
        var qualifiedForStreak: Bool = false
    }

    private func keyAllTime(userID: String) -> String { "speed_totals_alltime_\(userID)" }
    private func keyDaily(userID: String) -> String { "speed_totals_daily_\(userID)" } // [String: DailyBucket], key=yyyy-MM-dd

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()


    private let schemaVersionKey = "speed_analytics_schema_version"
    private let currentSchemaVersion = 1

    func migrateIfNeeded(activeUserID: String) {
        let defaults = UserDefaults.standard
        let installed = defaults.integer(forKey: schemaVersionKey)
        guard installed < currentSchemaVersion else { return }

        if !activeUserID.isEmpty {
            let oldAllTime = "speed_totals_alltime_"
            let oldDaily = "speed_totals_daily_"
            if defaults.data(forKey: keyAllTime(userID: activeUserID)) == nil,
               let legacy = defaults.data(forKey: oldAllTime) {
                defaults.set(legacy, forKey: keyAllTime(userID: activeUserID))
            }
            if defaults.data(forKey: keyDaily(userID: activeUserID)) == nil,
               let legacy = defaults.data(forKey: oldDaily) {
                defaults.set(legacy, forKey: keyDaily(userID: activeUserID))
            }
        }

        defaults.set(currentSchemaVersion, forKey: schemaVersionKey)
    }

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
        today.qualifiedForStreak = today.totalSeconds >= 300
        daily[dayKey] = today
        saveDaily(userID: userID, daily: daily)

        // Keep streak state in all-time totals.
        updateStreak(userID: userID, totals: &totals, daily: daily, todayKey: dayKey)
        saveTotals(userID: userID, totals: totals)
    }

    func recordTick(userID: String, rate: Float, delta: TimeInterval, category: String?) {
        guard delta > 0, rate > 0 else { return }
        recordTick(userID: userID, rate: rate, delta: delta)

        var daily = loadDaily(userID: userID)
        let dayKey = Self.dayKey(for: Date())
        var today = daily[dayKey] ?? DailyBucket()
        let weighted = Double(rate) * delta
        if (category ?? "").lowercased() == "fiction" {
            today.fictionSeconds += delta
            today.fictionWeightedRateSeconds += weighted
        } else if (category ?? "").lowercased() == "non-fiction" || (category ?? "").lowercased() == "nonfiction" {
            today.nonFictionSeconds += delta
            today.nonFictionWeightedRateSeconds += weighted
        }
        today.qualifiedForStreak = today.totalSeconds >= 300
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

    // THL = Total Hours Listened (real-time)
    func totalHoursListened(userID: String) -> Double {
        let totals = loadTotals(userID: userID)
        return totals.totalSeconds / 3600.0
    }

    // Material Hours = speed-adjusted covered hours
    func materialHoursCovered(userID: String) -> Double {
        let totals = loadTotals(userID: userID)
        return totals.weightedRateSeconds / 3600.0
    }

    func categoryHours(userID: String) -> (fiction: Double, nonFiction: Double) {
        let daily = loadDaily(userID: userID)
        let fiction = daily.values.reduce(0.0) { $0 + $1.fictionSeconds } / 3600.0
        let nonFiction = daily.values.reduce(0.0) { $0 + $1.nonFictionSeconds } / 3600.0
        return (fiction, nonFiction)
    }

    func currentStreak(userID: String) -> Int {
        let daily = loadDaily(userID: userID)
        let totals = loadTotals(userID: userID)
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())

        let todayKey = Self.dayKey(for: today)
        var anchorDate: Date = today
        if daily[todayKey]?.qualifiedForStreak != true {
            guard let yesterday = cal.date(byAdding: .day, value: -1, to: today) else {
                return fallbackStreakFromTotalsIfRecent(totals: totals, calendar: cal, today: today)
            }
            let yesterdayKey = Self.dayKey(for: yesterday)
            guard daily[yesterdayKey]?.qualifiedForStreak == true else {
                return fallbackStreakFromTotalsIfRecent(totals: totals, calendar: cal, today: today)
            }
            anchorDate = yesterday
        }

        var streak = 1
        var cursor = anchorDate
        while let prev = cal.date(byAdding: .day, value: -1, to: cursor) {
            let key = Self.dayKey(for: prev)
            guard daily[key]?.qualifiedForStreak == true else { break }
            streak += 1
            cursor = prev
        }

        return streak
    }

    private func fallbackStreakFromTotalsIfRecent(totals: Totals, calendar: Calendar, today: Date) -> Int {
        guard totals.currentStreakDays > 0,
              let lastKey = totals.lastQualifiedDayKey else { return 0 }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        guard let lastDate = formatter.date(from: lastKey) else { return 0 }
        let lastStart = calendar.startOfDay(for: lastDate)
        let diff = calendar.dateComponents([.day], from: lastStart, to: today).day ?? Int.max
        return diff <= 1 ? totals.currentStreakDays : 0
    }

    func longestStreak(userID: String) -> Int {
        let daily = loadDaily(userID: userID)
        let cal = Calendar(identifier: .gregorian)

        let formatter = DateFormatter()
        formatter.calendar = cal
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        let qualifiedDates: [Date] = daily.compactMap { key, bucket in
            guard bucket.qualifiedForStreak, let date = formatter.date(from: key) else { return nil }
            return cal.startOfDay(for: date)
        }.sorted()

        var longest = 0
        var running = 0
        var previous: Date?
        for date in qualifiedDates {
            if let prev = previous {
                let diff = cal.dateComponents([.day], from: prev, to: date).day ?? 0
                running = (diff == 1) ? (running + 1) : 1
            } else {
                running = 1
            }
            longest = max(longest, running)
            previous = date
        }
        return longest
    }

    func first3MonthRollingAverage(userID: String) -> Double? {
        loadTotals(userID: userID).first3MRAS
    }

    func current3MonthRollingAverage(userID: String) -> Double? {
        averageForLastDays(userID: userID, days: 90)
    }

    func current3MonthRollingAverageTimePerDay(userID: String) -> TimeInterval {
        let daily = loadDaily(userID: userID)
        let cal = Calendar(identifier: .gregorian)
        let today = cal.startOfDay(for: Date())
        var total: TimeInterval = 0
        var countedDays = 0

        for offset in 0..<90 {
            guard let date = cal.date(byAdding: .day, value: -offset, to: today) else { continue }
            let key = Self.dayKey(for: date)
            total += daily[key]?.totalSeconds ?? 0
            countedDays += 1
        }
        return countedDays > 0 ? total / Double(countedDays) : 0
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

    private func updateStreak(
        userID: String,
        totals: inout Totals,
        daily: [String: DailyBucket],
        todayKey: String
    ) {
        let cal = Calendar(identifier: .gregorian)
        let formatter = DateFormatter()
        formatter.calendar = cal
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        
        let qualifiedDates: [Date] = daily.compactMap { key, bucket in
            guard bucket.qualifiedForStreak, let date = formatter.date(from: key) else { return nil }
            return cal.startOfDay(for: date)
        }.sorted()

        var longest = 0
        var running = 0
        var previous: Date?
        for date in qualifiedDates {
            if let prev = previous {
                let diff = cal.dateComponents([.day], from: prev, to: date).day ?? 0
                running = (diff == 1) ? (running + 1) : 1
            } else {
                running = 1
            }
            longest = max(longest, running)
            previous = date
        }

        totals.longestStreakDays = max(totals.longestStreakDays, longest)

        if let todayDate = formatter.date(from: todayKey),
           daily[todayKey]?.qualifiedForStreak == true {
            var current = 1
            var cursor = cal.startOfDay(for: todayDate)
            while true {
                guard let prev = cal.date(byAdding: .day, value: -1, to: cursor) else { break }
                let prevKey = Self.dayKey(for: prev)
                if daily[prevKey]?.qualifiedForStreak == true {
                    current += 1
                    cursor = prev
                } else {
                    break
                }
            }
            totals.currentStreakDays = current
            totals.lastQualifiedDayKey = todayKey
        } else {
            totals.currentStreakDays = 0
        }

        // Capture first 3MRAS once after enough usage window.
        if totals.first3MRAS == nil,
           let avg90 = averageForLastDays(userID: userID, days: 90) {
            totals.first3MRAS = avg90
        }
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
