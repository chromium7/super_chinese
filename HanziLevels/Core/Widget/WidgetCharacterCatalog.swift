import Foundation

enum WidgetCharacterCatalog {
    enum CatalogError: Error {
        case invalidContent
    }

    /// Uses the same word membership as LibraryContent, without decoding strokes.
    static func load(level: Int, directory: URL?) throws -> [Hanzi] {
        guard let directory, directory.isFileURL else { throw CatalogError.invalidContent }
        let decoder = JSONDecoder()
        let words = try decoder.decode([Word].self, from: Data(contentsOf: directory.appendingPathComponent("words.v1.json")))
        let characters = try decoder.decode([Hanzi].self, from: Data(contentsOf: directory.appendingPathComponent("characters.v1.json")))
        let ids = Set(words.filter { $0.level == WidgetSettings.validLevel(level) }.flatMap(\.characters))
        let selected = characters.filter { ids.contains($0.id) }.sorted { $0.id < $1.id }
        guard !selected.isEmpty, Set(selected.map(\.id)) == ids,
              selected.count == ids.count,
              selected.allSatisfy({ $0.id.count == 1 && !$0.readings.isEmpty &&
                  $0.readings.allSatisfy { !$0.isEmpty } && !$0.meaning.isEmpty }) else {
            throw CatalogError.invalidContent
        }
        return selected
    }
}
