import Foundation

enum WidgetSettings {
    static let appGroup = "group.com.chromium7.HanziLevels"
    static let kind = "HSKCharacterWidget"
    static let levelKey = "currentHSKLevel"
    static let defaults = UserDefaults(suiteName: appGroup)

    static func validLevel(_ level: Int) -> Int {
        (1...5).contains(level) ? level : 1
    }

    static var currentLevel: Int {
        level(in: defaults)
    }

    static func level(in defaults: UserDefaults?) -> Int {
        validLevel(defaults?.integer(forKey: levelKey) ?? 1)
    }
}
