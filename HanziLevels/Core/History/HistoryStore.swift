import Foundation
import SwiftData

@MainActor
enum HistoryStore {
    static let limit = 50
    static let newestFirst = [SortDescriptor(\HistoryEntry.viewedAt, order: .reverse),
                              SortDescriptor(\HistoryEntry.key)]

    static func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(schema: Schema([HistoryEntry.self]),
                                               groupContainer: .none, cloudKitDatabase: .none)
        return try ModelContainer(for: HistoryEntry.self, configurations: configuration)
    }

    static func record(_ kind: HistoryKind, itemID: String, in context: ModelContext,
                       at date: Date = .now) throws {
        try save(in: context) {
            var entries = try context.fetch(FetchDescriptor<HistoryEntry>(sortBy: newestFirst))
            let key = kind.keyPrefix + itemID
            if let entry = entries.first(where: { $0.key == key }) {
                entry.viewedAt = date
            } else {
                let entry = HistoryEntry(kind: kind, itemID: itemID, viewedAt: date)
                context.insert(entry)
                entries.append(entry)
            }
            entries.sort {
                $0.viewedAt == $1.viewedAt ? $0.key < $1.key : $0.viewedAt > $1.viewedAt
            }
            for entry in entries.dropFirst(limit) { context.delete(entry) }
        }
    }

    static func delete(_ entries: [HistoryEntry], in context: ModelContext) throws {
        try save(in: context) {
            for entry in entries { context.delete(entry) }
        }
    }

    static func clear(in context: ModelContext) throws {
        try delete(context.fetch(FetchDescriptor<HistoryEntry>()), in: context)
    }

    private static func save(in context: ModelContext, changes: () throws -> Void) throws {
        do {
            try changes()
            try context.save()
        } catch {
            // This context stores only history; a failed write must not look successful.
            context.rollback()
            throw error
        }
    }
}
