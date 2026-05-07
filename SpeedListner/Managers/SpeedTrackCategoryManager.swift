import Foundation

final class SpeedTrackCategoryManager {
    static let shared = SpeedTrackCategoryManager()
    private init() {}

    func primaryLabel() -> String {
        UserDefaults.standard.string(forKey: UserKeys.categoryPrimaryLabel.rawValue) ?? "Fiction"
    }

    func secondaryLabel() -> String {
        UserDefaults.standard.string(forKey: UserKeys.categorySecondaryLabel.rawValue) ?? "Non-Fiction"
    }

    func setLabels(primary: String, secondary: String) {
        UserDefaults.standard.set(primary.trimmingCharacters(in: .whitespacesAndNewlines), forKey: UserKeys.categoryPrimaryLabel.rawValue)
        UserDefaults.standard.set(secondary.trimmingCharacters(in: .whitespacesAndNewlines), forKey: UserKeys.categorySecondaryLabel.rawValue)
    }

    func category(forBookId bookId: String) -> String? {
        guard let map = UserDefaults.standard.dictionary(forKey: UserKeys.categoryMap.rawValue) as? [String: String] else {
            return nil
        }
        return map[bookId]
    }

    func setCategory(_ category: String, forBookId bookId: String) {
        var map = UserDefaults.standard.dictionary(forKey: UserKeys.categoryMap.rawValue) as? [String: String] ?? [:]
        map[bookId] = category
        UserDefaults.standard.set(map, forKey: UserKeys.categoryMap.rawValue)
    }
}
