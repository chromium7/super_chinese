import XCTest
import SwiftUI

final class BrowsingTests: XCTestCase {
    @MainActor
    func testPreviewsUseDistinctCharactersInFirstAppearanceOrder() async throws {
        let bundled = try XCTUnwrap(Bundle(for: Self.self).resourceURL?.appendingPathComponent("Data", isDirectory: true))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.copyItem(at: bundled, to: directory)
        defer { try? FileManager.default.removeItem(at: directory) }

        let words = [
            Word(id: "我们学", syllables: ["wǒ", "men", "xué"], english: "we study", level: 1),
            Word(id: "我", syllables: ["wǒ"], english: "I", level: 1),
            Word(id: "中国学生", syllables: ["zhōng", "guó", "xué", "sheng"], english: "Chinese student", level: 2),
            Word(id: "你", syllables: ["nǐ"], english: "you", level: 3)
        ]
        let firstLevels = ["我": 1, "们": 1, "学": 1, "中": 2, "国": 2, "生": 2, "你": 3]
        let bundledCharacters = try JSONDecoder().decode([Hanzi].self, from: Data(contentsOf: bundled.appendingPathComponent("characters.v1.json")))
        let characters = bundledCharacters.compactMap { character -> Hanzi? in
            guard let firstLevel = firstLevels[character.id] else { return nil }
            return Hanzi(id: character.id, readings: character.readings, meaning: character.meaning,
                         strokeCount: character.strokeCount, firstLevel: firstLevel)
        }
        try JSONEncoder().encode(words).write(to: directory.appendingPathComponent("words.v1.json"))
        try JSONEncoder().encode(characters).write(to: directory.appendingPathComponent("characters.v1.json"))

        let library = Library()
        await library.load(directory: directory)
        XCTAssertEqual(library.state, .ready)
        // Two words with the same leading character still provide three distinct previews.
        XCTAssertEqual(library.previewCharacters(in: 1), "我们学")
        // One long word provides three characters, preserving order and limiting the count.
        XCTAssertEqual(library.previewCharacters(in: 2), "中国学")
        XCTAssertEqual(library.previewCharacters(in: 3), "你")
        XCTAssertEqual(library.previewCharacters(in: 4), "")
    }

    @MainActor
    func testModesPersistIndependentlyAcrossRecreation() throws {
        let name = "HanziLevelsTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let first = AppStorage(wrappedValue: LevelMode.words, BrowsingState.modeKey(for: 1), store: defaults)
        let second = AppStorage(wrappedValue: LevelMode.words, BrowsingState.modeKey(for: 2), store: defaults)
        let fifth = AppStorage(wrappedValue: LevelMode.words, BrowsingState.modeKey(for: 5), store: defaults)
        XCTAssertEqual(first.wrappedValue, .words)
        first.wrappedValue = .characters
        fifth.wrappedValue = .characters
        XCTAssertEqual(second.wrappedValue, .words)
        XCTAssertEqual(defaults.string(forKey: "levelMode.1"), "characters")
        let reopened = AppStorage(wrappedValue: LevelMode.words, "levelMode.1", store: defaults)
        XCTAssertEqual(reopened.wrappedValue, .characters)
        XCTAssertEqual(fifth.wrappedValue, .characters)
        first.wrappedValue = .words
        XCTAssertEqual(fifth.wrappedValue, .characters)
        defaults.set("unrecognized", forKey: "levelMode.3")
        let invalid = AppStorage(wrappedValue: LevelMode.words, "levelMode.3", store: defaults)
        XCTAssertEqual(invalid.wrappedValue, .words)
        XCTAssertEqual(Set(defaults.persistentDomain(forName: name)?.keys.map { $0 } ?? []),
                       Set(["levelMode.1", "levelMode.3", "levelMode.5"]))
    }

    @MainActor
    func testBrowsingPreservesBundledContentAndOrdering() async throws {
        let directory = try XCTUnwrap(Bundle(for: Self.self).resourceURL?.appendingPathComponent("Data", isDirectory: true))
        let library = Library()
        await library.load(directory: directory)
        XCTAssertEqual(library.state, .ready)
        let before = try XCTUnwrap(library.content)

        for level in 1...5 {
            XCTAssertEqual(library.searchWords("", level: level), before.wordsByLevel[level])
            _ = library.searchWords("student", level: level)
            XCTAssertEqual(library.searchCharacters("", level: level).map(\.id), before.characterIDsByLevel[level])
            _ = library.searchCharacters("xue", level: level)
            XCTAssertTrue(library.searchWords("no such vocabulary", level: level).isEmpty)
            XCTAssertTrue(library.searchCharacters("no such vocabulary", level: level).isEmpty)
        }

        let after = try XCTUnwrap(library.content)
        XCTAssertEqual(library.state, .ready)
        XCTAssertEqual(after.words, before.words)
        XCTAssertEqual(after.characters, before.characters)
        XCTAssertEqual(after.wordsByLevel, before.wordsByLevel)
        XCTAssertEqual(after.characterIDsByLevel, before.characterIDsByLevel)
        XCTAssertEqual(after.wordsByCharacter, before.wordsByCharacter)
        XCTAssertEqual(after.manifest.datasetVersion, before.manifest.datasetVersion)
    }
}
