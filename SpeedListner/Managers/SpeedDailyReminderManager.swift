import Foundation
import UserNotifications

final class SpeedDailyReminderManager {
    static let shared = SpeedDailyReminderManager()
    private init() {}

    private let requestPrefix = "speeddaily.reminder."
    private let cycleKey = "speeddaily.message.cycle"
    private let indexKey = "speeddaily.message.index"

    private let messages: [String] = [
        "Protect your streak. Give SpeedListener at least 5 focused minutes today.",
        "Your SpeedDaily streak is waiting. Press play and keep momentum alive.",
        "Small sessions compound. Hit 5 minutes now and keep your streak growing.",
        "Stay consistent today. One focused listening block keeps the fire burning.",
        "Don’t break the chain. Open SpeedListener and secure today’s streak.",
        "Every day counts. Listen for 5 minutes and move one step forward.",
        "Show up today. Your future speed and focus are built daily."
    ]

    func scheduleDailyReminder(hour: Int = 20, minute: Int = 0, daysAhead: Int = 30) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else { return }
            let center = UNUserNotificationCenter.current()
            center.getPendingNotificationRequests { pending in
                let existing = pending.map(\.identifier).filter { $0.hasPrefix(self.requestPrefix) }
                center.removePendingNotificationRequests(withIdentifiers: existing)

                let calendar = Calendar(identifier: .gregorian)
                let now = Date()
                let safeDays = max(1, min(daysAhead, 60))

                for offset in 0..<safeDays {
                    guard let date = calendar.date(byAdding: .day, value: offset, to: now) else { continue }
                    var comps = calendar.dateComponents([.year, .month, .day], from: date)
                    comps.hour = hour
                    comps.minute = minute

                    guard let fireDate = calendar.date(from: comps), fireDate > now else { continue }

                    let content = UNMutableNotificationContent()
                    content.title = "SpeedDaily Reminder"
                    content.body = self.nextMessage()
                    content.sound = .default

                    let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
                    let id = "\(self.requestPrefix)\(Self.dayKey(for: fireDate))"
                    let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
                    center.add(request)
                }
            }
        }
    }

    private func nextMessage() -> String {
        guard !messages.isEmpty else { return "Keep your SpeedDaily streak alive today." }

        var cycle = UserDefaults.standard.array(forKey: cycleKey) as? [Int] ?? []
        var index = UserDefaults.standard.integer(forKey: indexKey)

        if cycle.count != messages.count || Set(cycle).count != messages.count {
            cycle = Array(0..<messages.count).shuffled()
            index = 0
        }

        if index >= cycle.count {
            cycle = Array(0..<messages.count).shuffled()
            index = 0
        }

        let messageIndex = cycle[index]
        index += 1

        UserDefaults.standard.set(cycle, forKey: cycleKey)
        UserDefaults.standard.set(index, forKey: indexKey)

        return messages[messageIndex]
    }

    private static func dayKey(for date: Date) -> String {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = .init(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
}
