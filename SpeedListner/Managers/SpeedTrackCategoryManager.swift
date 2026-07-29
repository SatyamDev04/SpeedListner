import Foundation

final class SpeedTrackCategoryManager {
    static let shared = SpeedTrackCategoryManager()
    private init() {}

    static let categoryIDs = ["fiction", "non-fiction", "misc-1", "misc-2"]

    func primaryLabel() -> String {
        UserDefaults.standard.string(forKey: UserKeys.categoryPrimaryLabel.rawValue) ?? "Fiction"
    }

    func secondaryLabel() -> String {
        UserDefaults.standard.string(forKey: UserKeys.categorySecondaryLabel.rawValue) ?? "Non-Fiction"
    }

    func tertiaryLabel() -> String {
        UserDefaults.standard.string(forKey: UserKeys.categoryTertiaryLabel.rawValue) ?? "Misc 1"
    }

    func quaternaryLabel() -> String {
        UserDefaults.standard.string(forKey: UserKeys.categoryQuaternaryLabel.rawValue) ?? "Misc 2"
    }

    func labels() -> [String] {
        [primaryLabel(), secondaryLabel(), tertiaryLabel(), quaternaryLabel()]
    }

    func setLabels(primary: String, secondary: String, tertiary: String, quaternary: String) {
        UserDefaults.standard.set(primary.trimmingCharacters(in: .whitespacesAndNewlines), forKey: UserKeys.categoryPrimaryLabel.rawValue)
        UserDefaults.standard.set(secondary.trimmingCharacters(in: .whitespacesAndNewlines), forKey: UserKeys.categorySecondaryLabel.rawValue)
        UserDefaults.standard.set(tertiary.trimmingCharacters(in: .whitespacesAndNewlines), forKey: UserKeys.categoryTertiaryLabel.rawValue)
        UserDefaults.standard.set(quaternary.trimmingCharacters(in: .whitespacesAndNewlines), forKey: UserKeys.categoryQuaternaryLabel.rawValue)
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
