import Foundation

actor LibraryLoader {
    func load(directory: URL) throws -> LibraryContent {
        guard directory.isFileURL else { throw LibraryError.missingResources }
        return try LibraryContent(
            manifest: Data(contentsOf: directory.appendingPathComponent("manifest.json")),
            words: Data(contentsOf: directory.appendingPathComponent("words.v1.json")),
            characters: Data(contentsOf: directory.appendingPathComponent("characters.v1.json")),
            strokes: Data(contentsOf: directory.appendingPathComponent("strokes.v1.json"))
        )
    }
}
