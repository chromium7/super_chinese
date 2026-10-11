import Foundation
import Observation

@MainActor
@Observable
final class Library {
    enum State: Equatable {
        case loading
        case ready
        case failed(String)
    }

    private(set) var state: State = .loading
    private(set) var content: LibraryContent?
    @ObservationIgnored private var hasStartedLoading = false
    @ObservationIgnored private var strokeCache: [String: StrokeSet] = [:]

    var datasetVersion: String? { content?.manifest.datasetVersion }
    var words: [Word] { content?.words ?? [] }
    var characters: [Hanzi] { content?.characters ?? [] }

    func load(bundle: Bundle = .main) async {
        await load(directory: bundle.resourceURL?.appendingPathComponent("Data", isDirectory: true))
    }

    func load(directory: URL?) async {
        guard !hasStartedLoading else { return }
        hasStartedLoading = true
        do {
            guard let directory, directory.isFileURL else { throw LibraryError.missingResources }
            let loaded = try await LibraryLoader().load(directory: directory)
            content = loaded
            state = .ready
        } catch {
            fail(error)
        }
    }

    func word(id: String) -> Word? { content?.wordsByID[id] }
    func character(id: String) -> Hanzi? { content?.charactersByID[id] }
    func words(in level: Int) -> [Word] { content?.wordsByLevel[level] ?? [] }
    func characterIDs(in level: Int) -> [String] { content?.characterIDsByLevel[level] ?? [] }
    func words(containing characterID: String) -> [Word] { content?.wordsByCharacter[characterID] ?? [] }

    func searchWords(_ query: String, level: Int? = nil) -> [Word] {
        content?.searchIndex.searchWords(query, level: level) ?? []
    }

    func searchCharacters(_ query: String, level: Int? = nil) -> [Hanzi] {
        guard let content else { return [] }
        let ids = level.map { characterIDs(in: $0) } ?? content.characters.map(\.id)
        return content.searchIndex.searchCharacters(query, ids: ids)
    }

    func strokes(for characterID: String) throws -> StrokeSet? {
        if let cached = strokeCache[characterID] { return cached }
        guard let data = content?.strokeArchive.record(for: characterID), let hanzi = character(id: characterID) else { return nil }
        do {
            let strokes = try JSONDecoder().decode(StrokeSet.self, from: data)
            try strokes.validate(expectedCount: hanzi.strokeCount)
            strokeCache[characterID] = strokes
            return strokes
        } catch {
            fail(error)
            throw error
        }
    }

    private func fail(_ error: Error) {
        content = nil
        strokeCache.removeAll()
        state = .failed((error as? LibraryError)?.errorDescription ?? "The bundled content could not be read.")
    }
}
