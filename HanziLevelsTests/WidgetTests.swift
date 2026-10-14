import XCTest

final class WidgetTests: XCTestCase {
    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: seconds)
    }

    private var bundledDirectory: URL {
        #if SWIFT_PACKAGE
        Bundle.module.resourceURL!.appendingPathComponent("Data", isDirectory: true)
        #else
        Bundle(for: Self.self).resourceURL!.appendingPathComponent("Data", isDirectory: true)
        #endif
    }

    func testSelectionStaysWithinSlotAndChangesAtExactBoundary() throws {
        let characters = try WidgetCharacterCatalog.load(level: 1, directory: bundledDirectory)
        let start = date(100 * CharacterRotation.interval)
        let before = start.addingTimeInterval(CharacterRotation.interval - 0.001)
        XCTAssertEqual(CharacterRotation.character(at: start, from: characters),
                       CharacterRotation.character(at: before, from: characters))
        let next = CharacterRotation.nextChange(after: before)
        XCTAssertEqual(next, start.addingTimeInterval(8 * 60 * 60))
        XCTAssertNotEqual(CharacterRotation.character(at: before, from: characters),
                          CharacterRotation.character(at: next, from: characters))
        XCTAssertEqual(CharacterRotation.character(at: start, from: characters),
                       CharacterRotation.character(at: start.addingTimeInterval(Double(characters.count) * CharacterRotation.interval), from: characters))
    }

    func testWeekTimelineHasThreeChangesPer24HoursAndStrictlyFutureBoundaries() {
        // An arbitrary time away from a boundary, including the DST transition week.
        let now = date(1_762_051_500)
        let dates = CharacterRotation.dates(startingAt: now)
        XCTAssertEqual(dates.count, 22)
        XCTAssertEqual(dates.first, now)
        XCTAssertTrue(dates[1] > now)
        XCTAssertLessThanOrEqual(dates[1].timeIntervalSince(now), 8 * 60 * 60)
        XCTAssertEqual(dates.dropFirst().filter { $0 <= now.addingTimeInterval(24 * 60 * 60) }.count, 3)
        for index in 2..<dates.count {
            XCTAssertEqual(dates[index].timeIntervalSince(dates[index - 1]), 8 * 60 * 60)
        }
        XCTAssertEqual(CharacterRotation.nextChange(after: dates[1]), dates[2])
        XCTAssertEqual(CharacterRotation.nextChange(after: date(-1)), date(0))
    }

    func testEmptyAndSingleCharacterPoolsAreSafe() throws {
        XCTAssertNil(CharacterRotation.character(at: .now, from: []))
        let character = try XCTUnwrap(WidgetCharacterCatalog.load(level: 1, directory: bundledDirectory).first)
        XCTAssertEqual(CharacterRotation.character(at: date(-1), from: [character]), character)
        XCTAssertEqual(CharacterRotation.character(at: .now, from: [character]), character)
    }

    func testCatalogMatchesEachLevelsWordMembershipIncludingEarlierCharacters() throws {
        let words = try JSONDecoder().decode([Word].self, from: Data(contentsOf: bundledDirectory.appendingPathComponent("words.v1.json")))
        for level in 1...5 {
            let expected = Set(words.filter { $0.level == level }.flatMap(\.characters))
            let characters = try WidgetCharacterCatalog.load(level: level, directory: bundledDirectory)
            XCTAssertEqual(characters.map(\.id), expected.sorted())
            XCTAssertFalse(characters.isEmpty)
            XCTAssertTrue(characters.allSatisfy { !$0.readings.isEmpty && !$0.meaning.isEmpty })
        }
        let levelTwo = try WidgetCharacterCatalog.load(level: 2, directory: bundledDirectory)
        XCTAssertTrue(levelTwo.contains { $0.firstLevel == 1 })
        XCTAssertEqual(try WidgetCharacterCatalog.load(level: 0, directory: bundledDirectory),
                       try WidgetCharacterCatalog.load(level: 1, directory: bundledDirectory))
    }

    func testMissingMalformedAndInconsistentCatalogsFailLocally() throws {
        XCTAssertThrowsError(try WidgetCharacterCatalog.load(level: 1, directory: nil))
        XCTAssertThrowsError(try WidgetCharacterCatalog.load(level: 1, directory: URL(string: "https://example.com/Data")))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        XCTAssertThrowsError(try WidgetCharacterCatalog.load(level: 1, directory: directory))
        let words = Data("[]".utf8)
        try words.write(to: directory.appendingPathComponent("words.v1.json"))
        try Data("broken".utf8).write(to: directory.appendingPathComponent("characters.v1.json"))
        XCTAssertThrowsError(try WidgetCharacterCatalog.load(level: 1, directory: directory))
        try Data("[]".utf8).write(to: directory.appendingPathComponent("characters.v1.json"))
        XCTAssertThrowsError(try WidgetCharacterCatalog.load(level: 1, directory: directory))
        let character = try XCTUnwrap(WidgetCharacterCatalog.load(level: 1, directory: bundledDirectory).first)
        let word = Word(id: character.id, syllables: ["x"], english: "test", level: 1)
        try JSONEncoder().encode([word]).write(to: directory.appendingPathComponent("words.v1.json"))
        XCTAssertThrowsError(try WidgetCharacterCatalog.load(level: 1, directory: directory))
        try JSONEncoder().encode([character, character]).write(to: directory.appendingPathComponent("characters.v1.json"))
        XCTAssertThrowsError(try WidgetCharacterCatalog.load(level: 1, directory: directory))
    }

    func testCharacterLinksRoundTripHanziAndRejectInvalidRoutes() throws {
        for id in ["学", "女", "𠀀"] {
            let url = try XCTUnwrap(CharacterLink.url(for: id))
            XCTAssertEqual(CharacterLink.characterID(from: url), id)
        }
        XCTAssertNil(CharacterLink.url(for: ""))
        XCTAssertNil(CharacterLink.url(for: "学生"))
        for raw in ["https://character?id=学", "hanzilevels://word?id=学",
                    "hanzilevels://character", "hanzilevels://character?id=学生",
                    "hanzilevels://character?id=学&id=女", "hanzilevels://character/path?id=学",
                    "hanzilevels://character?id=学#fragment", "hanzilevels://character?id="] {
            // Percent-encode for older Foundation versions as well.
            let url = try XCTUnwrap(URL(string: raw.addingPercentEncoding(withAllowedCharacters: .urlFragmentAllowed)!))
            XCTAssertNil(CharacterLink.characterID(from: url), raw)
        }
    }

    func testStudyLevelPersistsAndInvalidPreferencesFallBack() throws {
        let suite = "WidgetTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        XCTAssertEqual(WidgetSettings.level(in: defaults), 1)
        defaults.set(4, forKey: WidgetSettings.levelKey)
        XCTAssertEqual(WidgetSettings.level(in: UserDefaults(suiteName: suite)), 4)
        for invalid in [-1, 0, 6, 99] {
            defaults.set(invalid, forKey: WidgetSettings.levelKey)
            XCTAssertEqual(WidgetSettings.level(in: defaults), 1)
        }
        XCTAssertEqual(WidgetSettings.level(in: nil), 1)
    }
}
