import XCTest

final class SourceDocumentTests: XCTestCase {
    private func directory() throws -> URL {
        try XCTUnwrap(Bundle(for: Self.self).resourceURL?.appendingPathComponent("Data/Licenses", isDirectory: true))
    }

    func testBundledDocumentsAreReadInFullWithoutModification() async throws {
        let directory = try directory()
        let documents = await SourceDocumentLoader().load(directory: directory)
        XCTAssertEqual(documents.count, 3)
        for document in SourceDocument.allCases {
            let original = try String(contentsOf: directory.appendingPathComponent(document.rawValue), encoding: .utf8)
            XCTAssertEqual(documents[document], original)
            XCTAssertFalse(original.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        let notes = try XCTUnwrap(documents[.notes])
        XCTAssertTrue(notes.contains("No written redistribution permission or approved replacement was supplied."))
        XCTAssertTrue(notes.contains("Release remains blocked"))
        XCTAssertTrue(notes.contains("Original upstream definition/stroke revisions were not supplied"))
        XCTAssertTrue(notes.contains("CC-BY-SA-3.0.txt"))
        XCTAssertTrue(notes.contains("ARPHICPL.TXT"))
    }

    func testUnavailableOrRemoteDirectoryCannotLoadDocuments() async throws {
        let loader = SourceDocumentLoader()
        let missing = await loader.load(directory: nil)
        XCTAssertTrue(missing.isEmpty)
        let remote = await loader.load(directory: URL(string: "https://example.invalid/Licenses"))
        XCTAssertTrue(remote.isEmpty)
    }

    func testMissingUnreadableAndEmptyDocumentsAreIsolatedAndCanBeRetried() async throws {
        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporary) }
        let notes = "Permission pending.\n"
        try notes.write(to: temporary.appendingPathComponent(SourceDocument.notes.rawValue), atomically: true, encoding: .utf8)
        let loader = SourceDocumentLoader()
        var documents = await loader.load(directory: temporary)
        XCTAssertEqual(documents, [.notes: notes])

        let arphic = temporary.appendingPathComponent(SourceDocument.arphic.rawValue)
        let definitions = temporary.appendingPathComponent(SourceDocument.definitions.rawValue)
        try Data([0xFF, 0xFE, 0xFF]).write(to: arphic)
        try " \n\t".write(to: definitions, atomically: true, encoding: .utf8)
        documents = await loader.load(directory: temporary)
        XCTAssertEqual(documents, [.notes: notes])

        try "Arphic text\n".write(to: arphic, atomically: true, encoding: .utf8)
        try "Creative Commons text\n".write(to: definitions, atomically: true, encoding: .utf8)
        documents = await loader.load(directory: temporary)
        XCTAssertEqual(documents, [.notes: notes, .arphic: "Arphic text\n", .definitions: "Creative Commons text\n"])
    }
}
