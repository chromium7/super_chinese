import Foundation
import SwiftData

@Model
final class HistoryEntry {
    @Attribute(.unique) var key: String
    var kind: String
    var itemID: String
    var viewedAt: Date

    init(kind: HistoryKind, itemID: String, viewedAt: Date = .now) {
        self.key = kind.keyPrefix + itemID
        self.kind = kind.rawValue
        self.itemID = itemID
        self.viewedAt = viewedAt
    }
}
