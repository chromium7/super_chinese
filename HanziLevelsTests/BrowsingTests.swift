import XCTest

final class BrowsingTests: XCTestCase {
    @MainActor
    func testModeSelectionsAreIndependentAndSurviveRevisitingLevels() async {
        let state = BrowsingState()
        XCTAssertEqual(state.modes[1, default: .words], .words)
        state.modes[1] = .characters
        XCTAssertEqual(state.modes[2, default: .words], .words)
        state.modes[2] = .words
        state.modes[5] = .characters
        XCTAssertEqual(state.modes[1, default: .words], .characters)
        XCTAssertEqual(state.modes[2, default: .words], .words)
        XCTAssertEqual(state.modes[5, default: .words], .characters)
        XCTAssertEqual(BrowsingState().modes[1, default: .words], .words)
    }

    @MainActor
    func testBrowsingAndChangingModesPreservesBundledContentAndOrdering() async throws {
        let directory = try XCTUnwrap(Bundle(for: Self.self).resourceURL?.appendingPathComponent("Data", isDirectory: true))
        let library = Library()
        await library.load(directory: directory)
        XCTAssertEqual(library.state, .ready)
        let before = try XCTUnwrap(library.content)
        let state = BrowsingState()

        for level in 1...5 {
            state.modes[level] = .words
            XCTAssertEqual(library.searchWords("", level: level), before.wordsByLevel[level])
            _ = library.searchWords("student", level: level)
            state.modes[level] = .characters
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
