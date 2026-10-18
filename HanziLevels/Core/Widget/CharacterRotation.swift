import Foundation

enum CharacterRotation {
    static let interval: TimeInterval = 8 * 60 * 60

    /// Epoch-based slots keep an exact eight-hour cadence across DST and travel.
    static func slot(at date: Date) -> Int {
        Int(floor(date.timeIntervalSince1970 / interval))
    }

    static func nextChange(after date: Date) -> Date {
        Date(timeIntervalSince1970: Double(slot(at: date) + 1) * interval)
    }

    static func character(at date: Date, from characters: [Hanzi]) -> Hanzi? {
        guard !characters.isEmpty else { return nil }
        let index = ((slot(at: date) % characters.count) + characters.count) % characters.count
        return characters[index]
    }

    /// Precompute a week so rotation continues while the app remains closed.
    static func dates(startingAt date: Date) -> [Date] {
        let next = nextChange(after: date)
        return [date] + (0..<21).map { next.addingTimeInterval(Double($0) * interval) }
    }
}
