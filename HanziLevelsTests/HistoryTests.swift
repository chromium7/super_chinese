import XCTest
import SwiftData

final class HistoryTests: XCTestCase {
    private enum SaveFailure: Error { case injected }

    @MainActor
    private func failSave(_ context: ModelContext) throws {
        XCTAssertTrue(context.hasChanges, "Inject failure only after applying the history operation.")
        throw SaveFailure.injected
    }

    @MainActor
    private func container() throws -> ModelContainer {
        try ModelContainer(for: HistoryEntry.self,
                           configurations: ModelConfiguration(schema: Schema([HistoryEntry.self]),
                                                              isStoredInMemoryOnly: true,
                                                              cloudKitDatabase: .none))
    }

    @MainActor
    private func entries(in context: ModelContext) throws -> [HistoryEntry] {
        try context.fetch(FetchDescriptor<HistoryEntry>(sortBy: HistoryStore.newestFirst))
    }

    @MainActor
    func testRepeatedAppearanceUpdatesOneKeyAndMovesItToNewest() throws {
        let container = try container()
        let context = container.mainContext
        try HistoryStore.record(.word, itemID: "学生", in: context, at: Date(timeIntervalSince1970: 1))
        try HistoryStore.record(.character, itemID: "学", in: context, at: Date(timeIntervalSince1970: 2))
        try HistoryStore.record(.word, itemID: "学生", in: context, at: Date(timeIntervalSince1970: 3))
        let result = try entries(in: context)
        XCTAssertEqual(result.map(\.key), ["w:学生", "c:学"])
        XCTAssertEqual(result[0].viewedAt, Date(timeIntervalSince1970: 3))
        XCTAssertEqual(result[0].kind, "word")
        XCTAssertEqual(result[0].itemID, "学生")
    }

    @MainActor
    func testWordAndCharacterWithSameHanziHaveDistinctKeys() throws {
        let container = try container()
        let context = container.mainContext
        for _ in 0..<3 {
            try HistoryStore.record(.word, itemID: "我", in: context)
            try HistoryStore.record(.character, itemID: "我", in: context)
        }
        XCTAssertEqual(Set(try entries(in: context).map(\.key)), ["w:我", "c:我"])
    }

    @MainActor
    func testInsertsTrimOldestEntriesAndPreserveNewestFirst() throws {
        let container = try container()
        let context = container.mainContext
        for index in 0..<60 {
            try HistoryStore.record(.word, itemID: "item\(index)", in: context,
                                    at: Date(timeIntervalSince1970: Double(index)))
        }
        let result = try entries(in: context)
        XCTAssertEqual(result.count, 50)
        XCTAssertEqual(result.map(\.itemID), (10..<60).reversed().map { "item\($0)" })
        XCTAssertEqual(Array(result.prefix(5)).map(\.itemID), ["item59", "item58", "item57", "item56", "item55"])
    }

    @MainActor
    func testRevisitedOldEntrySurvivesNextTrim() throws {
        let container = try container()
        let context = container.mainContext
        for index in 0..<50 {
            try HistoryStore.record(.word, itemID: "item\(index)", in: context,
                                    at: Date(timeIntervalSince1970: Double(index)))
        }
        try HistoryStore.record(.word, itemID: "item0", in: context, at: Date(timeIntervalSince1970: 100))
        try HistoryStore.record(.character, itemID: "学", in: context, at: Date(timeIntervalSince1970: 101))
        let result = try entries(in: context)
        XCTAssertEqual(result.count, 50)
        XCTAssertEqual(result.prefix(2).map(\.key), ["c:学", "w:item0"])
        XCTAssertFalse(result.contains { $0.itemID == "item1" })
    }

    @MainActor
    func testDeletionRemovesOnlySelectedEntries() throws {
        let container = try container()
        let context = container.mainContext
        try HistoryStore.record(.word, itemID: "学生", in: context)
        try HistoryStore.record(.character, itemID: "学", in: context)
        let selected = try XCTUnwrap(try entries(in: context).first { $0.kind == "word" })
        try HistoryStore.delete([selected], in: context)
        XCTAssertEqual(try entries(in: context).map(\.key), ["c:学"])
    }

    @MainActor
    func testClearIsIdempotentAndAllowsNewHistory() throws {
        let container = try container()
        let context = container.mainContext
        try HistoryStore.record(.word, itemID: "学生", in: context)
        try HistoryStore.record(.character, itemID: "学", in: context)
        try HistoryStore.clear(in: context)
        XCTAssertTrue(try entries(in: context).isEmpty)
        try HistoryStore.clear(in: context)
        try HistoryStore.record(.word, itemID: "我", in: context)
        XCTAssertEqual(try entries(in: context).map(\.key), ["w:我"])
    }

    @MainActor
    func testHistoryAndClearPersistWhenLocalStoreIsReopened() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let configuration = ModelConfiguration(schema: Schema([HistoryEntry.self]),
                                               url: directory.appendingPathComponent("history.store"),
                                               cloudKitDatabase: .none)
        let date = Date(timeIntervalSince1970: 123)
        do {
            let first = try ModelContainer(for: HistoryEntry.self, configurations: configuration)
            try HistoryStore.record(.word, itemID: "学生", in: first.mainContext, at: date)
        }
        do {
            let reopened = try ModelContainer(for: HistoryEntry.self, configurations: configuration)
            let result = try entries(in: reopened.mainContext)
            XCTAssertEqual(result.map(\.key), ["w:学生"])
            XCTAssertEqual(result.first?.viewedAt, date)
            try HistoryStore.clear(in: reopened.mainContext)
        }
        let cleared = try ModelContainer(for: HistoryEntry.self, configurations: configuration)
        XCTAssertTrue(try entries(in: cleared.mainContext).isEmpty)
    }

    @MainActor
    func testFailedInsertRestoresTrimmedEntryAndAllowsRetry() throws {
        let container = try container()
        let context = container.mainContext
        for index in 0..<50 {
            try HistoryStore.record(.word, itemID: "item\(index)", in: context,
                                    at: Date(timeIntervalSince1970: Double(index)))
        }
        let expected = try entries(in: context).map(\.key)
        XCTAssertThrowsError(try HistoryStore.record(.character, itemID: "学", in: context,
                                                     at: Date(timeIntervalSince1970: 100), save: failSave)) {
            XCTAssertTrue($0 is SaveFailure)
        }
        XCTAssertFalse(context.hasChanges)
        XCTAssertEqual(try entries(in: context).map(\.key), expected)
        // A separate context must still see the committed history, including the trimmed oldest entry.
        XCTAssertEqual(try entries(in: ModelContext(container)).map(\.key), expected)
        try HistoryStore.record(.character, itemID: "学", in: context, at: Date(timeIntervalSince1970: 100))
        let result = try entries(in: context)
        XCTAssertEqual(result.count, 50)
        XCTAssertEqual(result.first?.key, "c:学")
        XCTAssertFalse(result.contains { $0.itemID == "item0" })
    }

    @MainActor
    func testFailedRevisitRestoresTimestampAndOrdering() throws {
        let container = try container()
        let context = container.mainContext
        let original = Date(timeIntervalSince1970: 1)
        try HistoryStore.record(.word, itemID: "学生", in: context, at: original)
        try HistoryStore.record(.character, itemID: "学", in: context, at: Date(timeIntervalSince1970: 2))
        XCTAssertThrowsError(try HistoryStore.record(.word, itemID: "学生", in: context,
                                                     at: Date(timeIntervalSince1970: 3), save: failSave)) {
            XCTAssertTrue($0 is SaveFailure)
        }
        XCTAssertFalse(context.hasChanges)
        let result = try entries(in: context)
        XCTAssertEqual(result.map(\.key), ["c:学", "w:学生"])
        XCTAssertEqual(result.last?.viewedAt, original)
        XCTAssertEqual(try entries(in: ModelContext(container)).last?.viewedAt, original)
    }

    @MainActor
    func testFailedDeleteAndClearRestoreHistoryAndAllowRetry() throws {
        let container = try container()
        let context = container.mainContext
        try HistoryStore.record(.word, itemID: "学生", in: context, at: Date(timeIntervalSince1970: 1))
        try HistoryStore.record(.character, itemID: "学", in: context, at: Date(timeIntervalSince1970: 2))
        let expected = try entries(in: context).map(\.key)
        let selected = try XCTUnwrap(try entries(in: context).first)
        XCTAssertThrowsError(try HistoryStore.delete([selected], in: context, save: failSave)) {
            XCTAssertTrue($0 is SaveFailure)
        }
        XCTAssertFalse(context.hasChanges)
        XCTAssertEqual(try entries(in: context).map(\.key), expected)
        XCTAssertThrowsError(try HistoryStore.clear(in: context, save: failSave)) {
            XCTAssertTrue($0 is SaveFailure)
        }
        XCTAssertFalse(context.hasChanges)
        XCTAssertEqual(try entries(in: context).map(\.key), expected)
        XCTAssertEqual(try entries(in: ModelContext(container)).map(\.key), expected)
        try HistoryStore.clear(in: context)
        XCTAssertTrue(try entries(in: ModelContext(container)).isEmpty)
    }
}
