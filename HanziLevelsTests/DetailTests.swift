import XCTest

final class DetailTests: XCTestCase {
    private func directory() throws -> URL {
        try XCTUnwrap(Bundle(for: Self.self).resourceURL?.appendingPathComponent("Data", isDirectory: true))
    }

    func testWordCharactersAreUniqueInReadingOrder() {
        let word = Word(id: "人人学人人", syllables: ["rén", "rén", "xué", "rén", "rén"],
                        english: "everyone studies", level: 1)
        XCTAssertEqual(word.uniqueCharacterIDs, ["人", "学"])
        XCTAssertEqual(word.characters, ["人", "人", "学", "人", "人"])
        XCTAssertEqual(Word(id: "", syllables: [], english: "", level: 1).uniqueCharacterIDs, [])
    }

    @MainActor
    func testEveryDetailRelationshipResolvesWithoutChangingLibrary() async throws {
        let library = Library()
        await library.load(directory: try directory())
        XCTAssertEqual(library.state, .ready)
        let before = try XCTUnwrap(library.content)

        for word in library.words {
            for id in word.uniqueCharacterIDs {
                let character = try XCTUnwrap(library.character(id: id))
                XCTAssertFalse(character.readings.isEmpty)
                XCTAssertFalse(character.meaning.isEmpty)
                XCTAssertGreaterThan(character.strokeCount, 0)
                let containing = library.words(containing: id)
                XCTAssertEqual(containing, before.words.filter { $0.characters.contains(id) })
                XCTAssertTrue(containing.contains(word))
                XCTAssertEqual(character.firstLevel, containing.map(\.level).min())
                for related in containing {
                    XCTAssertEqual(library.word(id: related.id), related)
                }
            }
        }
        // The character detail list includes relationships from multiple levels.
        XCTAssertGreaterThan(Set(library.words(containing: "生").map(\.level)).count, 1)
        XCTAssertEqual(library.content?.words, before.words)
        XCTAssertEqual(library.content?.characters, before.characters)
        XCTAssertEqual(library.state, .ready)
    }

    @MainActor
    func testMissingDetailIDsLeaveLocalLibraryAvailable() async throws {
        let library = Library()
        XCTAssertNil(library.word(id: "missing"))
        XCTAssertNil(library.character(id: "missing"))
        await library.load(directory: try directory())
        XCTAssertNil(library.word(id: "missing"))
        XCTAssertNil(library.character(id: "missing"))
        XCTAssertTrue(library.words(containing: "missing").isEmpty)
        XCTAssertNotNil(library.word(id: "学生"))
        XCTAssertEqual(library.state, .ready)
    }

    @MainActor
    func testDetailMetadataDoesNotDecodeStrokePlaybackRecords() async throws {
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.copyItem(at: directory(), to: temporary)
        defer { try? FileManager.default.removeItem(at: temporary) }
        let strokeURL = temporary.appendingPathComponent("strokes.v1.json")
        var records = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: strokeURL)) as? [String: Any])
        records["学"] = ["strokes": ["invalid playback data"], "medians": "invalid"]
        try JSONSerialization.data(withJSONObject: records).write(to: strokeURL)

        let library = Library()
        await library.load(directory: temporary)
        XCTAssertEqual(library.state, .ready)
        XCTAssertEqual(library.word(id: "学生")?.uniqueCharacterIDs, ["学", "生"])
        XCTAssertNotNil(library.character(id: "学"))
        XCTAssertTrue(library.words(containing: "学").contains { $0.id == "学生" })
        XCTAssertEqual(library.state, .ready)
    }
}
