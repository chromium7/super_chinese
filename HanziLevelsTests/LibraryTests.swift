import XCTest

final class LibraryTests: XCTestCase {
    private func directory() throws -> URL {
        let bundle = Bundle(for: Self.self)
        return try XCTUnwrap(bundle.resourceURL?.appendingPathComponent("Data", isDirectory: true))
    }

    private func data(_ name: String) throws -> Data {
        try Data(contentsOf: directory().appendingPathComponent(name))
    }

    private func content(manifest: Data? = nil, words: Data? = nil, characters: Data? = nil, strokes: Data? = nil) throws -> LibraryContent {
        try LibraryContent(
            manifest: manifest ?? data("manifest.json"),
            words: words ?? data("words.v1.json"),
            characters: characters ?? data("characters.v1.json"),
            strokes: strokes ?? data("strokes.v1.json")
        )
    }

    private func modified(_ name: String, change: (inout Any) -> Void) throws -> Data {
        var object = try JSONSerialization.jsonObject(with: data(name))
        change(&object)
        return try JSONSerialization.data(withJSONObject: object)
    }

    func testPinyinFormattingAndNormalization() {
        XCTAssertEqual(PinyinFormatter.format(["nǚ", "ér"]), "nǚ'ér")
        XCTAssertEqual(PinyinFormatter.format(["xué", "sheng"]), "xuésheng")
        XCTAssertEqual(PinyinFormatter.format(["xī", "ān"]), "xī'ān")
        XCTAssertEqual(PinyinFormatter.format(["tiān", "é"]), "tiān'é")
        XCTAssertEqual(PinyinFormatter.format(["jǐ", "ǒu"]), "jǐ'ǒu")
        XCTAssertEqual(PinyinFormatter.format([]), "")
        XCTAssertEqual(PinyinFormatter.format(["ài"]), "ài")
        for query in ["nǚ'ér", "nü er", "nv’er", "NU\u{0308}\u{030c} ER"] {
            XCTAssertEqual(PinyinFormatter.normalize(query), "nver")
        }
        XCTAssertNotEqual(PinyinFormatter.normalize("lü"), PinyinFormatter.normalize("lu"))
    }

    func testSuppliedWordSearchExamples() throws {
        let index = try content().searchIndex
        for query in ["xue sheng", "xuesheng", "xuésheng", "XUÉ SHENG", "student", "STUDENT", "学生", " 学生 \n"] {
            XCTAssertTrue(index.searchWords(query, level: 1).contains(where: { $0.id == "学生" }), query)
        }
        XCTAssertTrue(index.searchWords("学生", level: 5).isEmpty)
        XCTAssertTrue(index.searchWords("not a real definition").isEmpty)
        XCTAssertTrue(index.searchWords("''").isEmpty)
        XCTAssertEqual(index.searchWords(" \n").count, 131)
        XCTAssertEqual(index.searchWords("", level: 1), try content().wordsByLevel[1])
    }

    func testUmlautWordSearchAndCharacterReadingPrefix() {
        let word = Word(id: "女儿", syllables: ["nǚ", "ér"], english: "daughter", level: 1)
        let characters = [
            Hanzi(id: "女", readings: ["nǚ"], meaning: "woman", strokeCount: 3, firstLevel: 1),
            Hanzi(id: "儿", readings: ["ér"], meaning: "child", strokeCount: 2, firstLevel: 1)
        ]
        let index = SearchIndex(words: [word], characters: characters)
        for query in ["nver", "nü er", "nǚ'ér", "nv’er"] {
            XCTAssertEqual(index.searchWords(query), [word])
        }
        for query in ["n", "nv", "NÜ", "女", "WOMAN"] {
            XCTAssertEqual(index.searchCharacters(query, ids: ["女", "儿"]).map(\.id), ["女"])
        }
        XCTAssertTrue(index.searchCharacters("v", ids: ["女"]).isEmpty)
        XCTAssertEqual(index.searchCharacters("", ids: ["儿", "女"]).map(\.id), ["儿", "女"])
    }

    func testAllBundledRelationshipsAndStrokeCounts() throws {
        let library = try content()
        XCTAssertEqual(library.words.count, 131)
        XCTAssertEqual(library.characters.count, 213)
        for word in library.words {
            XCTAssertEqual(library.wordsByID[word.id], word)
            for id in word.characters {
                let hanzi = try XCTUnwrap(library.charactersByID[id])
                XCTAssertTrue(try XCTUnwrap(library.wordsByCharacter[id]).contains(word))
                let strokes = try JSONDecoder().decode(StrokeSet.self, from: XCTUnwrap(library.strokeArchive.record(for: id)))
                XCTAssertNoThrow(try strokes.validate(expectedCount: hanzi.strokeCount))
            }
        }
        for hanzi in library.characters {
            XCTAssertEqual(library.charactersByID[hanzi.id], hanzi)
        }
        for level in 1...5 {
            var seen: Set<String> = []
            let expected = (library.wordsByLevel[level] ?? []).flatMap(\.characters).filter { seen.insert($0).inserted }
            XCTAssertEqual(library.characterIDsByLevel[level] ?? [], expected)
        }
    }

    func testRepeatedCharactersProduceOneRelationship() throws {
        let words = try modified("words.v1.json") { object in
            var words = object as! [[String: Any]]
            words.append(["id": "学学", "syllables": ["xué", "xué"], "english": "learn repeatedly", "level": 1])
            object = words
        }
        let library = try content(words: words)
        XCTAssertEqual(library.wordsByCharacter["学"]?.filter { $0.id == "学学" }.count, 1)
        XCTAssertEqual(library.characterIDsByLevel[1]?.filter { $0 == "学" }.count, 1)
    }

    func testSchemaAndDecodeFailures() throws {
        let manifest = try modified("manifest.json") { object in
            var manifest = object as! [String: Any]
            manifest["schemaVersion"] = 2
            object = manifest
        }
        XCTAssertThrowsError(try content(manifest: manifest)) { error in
            XCTAssertEqual(error as? LibraryError, .unsupportedSchema(2))
        }
        XCTAssertThrowsError(try content(words: Data("broken".utf8)))
        XCTAssertThrowsError(try content(strokes: Data("[]".utf8)))
        let words = try modified("words.v1.json") { object in
            var words = object as! [[String: Any]]
            words.append(words[0])
            object = words
        }
        XCTAssertThrowsError(try content(words: words))
        let missing = try modified("characters.v1.json") { object in
            var characters = object as! [[String: Any]]
            characters.removeFirst()
            object = characters
        }
        XCTAssertThrowsError(try content(characters: missing))
    }

    func testStrokeArchiveSlicesEscapedKeysAndNestedRecords() throws {
        let source = #"{ "\u5b66": {"strokes":["M 0 0 \"quoted\" \\ tail { } [ ]"],"medians":[[[0,0]]]}, "生": {"strokes":["M 1 1"],"medians":[[[1,1]]]}}"#
        let archive = try StrokeArchive(data: Data(source.utf8))
        XCTAssertTrue(archive.contains("学"))
        XCTAssertNil(archive.record(for: "missing"))
        let record = try XCTUnwrap(archive.record(for: "学"))
        let strokes = try JSONDecoder().decode(StrokeSet.self, from: record)
        XCTAssertEqual(strokes.strokes, [#"M 0 0 "quoted" \ tail { } [ ]"#])
        XCTAssertNoThrow(try strokes.validate(expectedCount: 1))
        // Record contents are not parsed at indexing time, even if their JSON is invalid.
        let lazy = try StrokeArchive(data: Data(#"{"学":{"strokes":notJSON}}"#.utf8))
        XCTAssertThrowsError(try JSONDecoder().decode(StrokeSet.self, from: XCTUnwrap(lazy.record(for: "学"))))
    }

    func testStrokeArchiveRejectsInvalidBoundariesAndDuplicateKeys() {
        for source in ["[]", "{", #"{"学":[]}"#, #"{"学":{},}"#,
                       #"{"学":{},"学":{}}"#, #"{"学":{"medians":[}}"#,
                       #"{"学":{"strokes":["unfinished]}}"#, #"{"学":{}} trailing"#] {
            XCTAssertThrowsError(try StrokeArchive(data: Data(source.utf8)))
        }
    }

    @MainActor
    func testLibraryLoadsOnceAndExposesLookups() async throws {
        let library = Library()
        XCTAssertEqual(library.state, .loading)
        await library.load(directory: try directory())
        XCTAssertEqual(library.state, .ready)
        XCTAssertEqual(library.datasetVersion, "2026.10.0-sample")
        let student = try XCTUnwrap(library.word(id: "学生"))
        XCTAssertTrue(library.words(in: 1).contains(student))
        XCTAssertTrue(library.words(containing: "学").contains(student))
        XCTAssertTrue(library.characterIDs(in: 1).contains("学"))
        XCTAssertEqual(library.searchWords("xue sheng", level: 1).map(\.id), ["学生"])
        XCTAssertTrue(library.searchCharacters("xue", level: 1).contains(where: { $0.id == "学" }))
        XCTAssertNil(library.word(id: "missing"))
        XCTAssertTrue(library.words(in: 6).isEmpty)
        XCTAssertTrue(library.searchCharacters("", level: 6).isEmpty)
        let first = try XCTUnwrap(library.strokes(for: "学"))
        XCTAssertEqual(first, try library.strokes(for: "学"))
        XCTAssertNil(try library.strokes(for: "missing"))
        await library.load(directory: nil)
        XCTAssertEqual(library.state, .ready)
    }

    @MainActor
    func testMissingBundleExposesPlainFailure() async {
        let library = Library()
        await library.load(directory: nil)
        XCTAssertEqual(library.state, .failed("The bundled content is missing."))
        XCTAssertTrue(library.words.isEmpty)
        XCTAssertTrue(library.searchWords("student").isEmpty)
    }

    @MainActor
    func testMalformedBundleExposesPlainFailure() async throws {
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.copyItem(at: directory(), to: temporary)
        defer { try? FileManager.default.removeItem(at: temporary) }
        try Data("not JSON".utf8).write(to: temporary.appendingPathComponent("words.v1.json"))
        let library = Library()
        await library.load(directory: temporary)
        XCTAssertEqual(library.state, .failed("The bundled content could not be read."))
        XCTAssertTrue(library.characters.isEmpty)
        XCTAssertNil(library.content)
    }

    @MainActor
    func testLoaderRejectsRemoteDirectories() async throws {
        let remote = try XCTUnwrap(URL(string: "https://example.invalid/Data"))
        do {
            _ = try await LibraryLoader().load(directory: remote)
            XCTFail("Remote directories must be rejected before reading files.")
        } catch {
            XCTAssertEqual(error as? LibraryError, .missingResources)
        }
    }

    @MainActor
    func testStrokeDecodeIsLazyAndFailureClearsLibrary() async throws {
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.copyItem(at: directory(), to: temporary)
        defer { try? FileManager.default.removeItem(at: temporary) }
        let strokes = try modified("strokes.v1.json") { object in
            var archive = object as! [String: Any]
            archive["学"] = ["strokes": ["M 0 0"], "medians": "invalid"]
            object = archive
        }
        try strokes.write(to: temporary.appendingPathComponent("strokes.v1.json"))
        let library = Library()
        await library.load(directory: temporary)
        XCTAssertEqual(library.state, .ready)
        XCTAssertNotNil(try library.strokes(for: "生"))
        XCTAssertThrowsError(try library.strokes(for: "学"))
        XCTAssertEqual(library.state, .failed("The bundled content could not be read."))
        XCTAssertNil(library.content)
        XCTAssertNil(try library.strokes(for: "生"))
    }
}
