import Foundation
import WidgetKit

struct CharacterEntry: TimelineEntry {
    let date: Date
    let level: Int
    let character: Hanzi?

    static let sample = CharacterEntry(
        date: .now, level: 1,
        character: Hanzi(id: "学", readings: ["xué"], meaning: "to study; to learn",
                         strokeCount: 8, firstLevel: 1)
    )
}
