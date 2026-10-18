import Foundation
import Observation

@MainActor
@Observable
final class LevelViewModel {
    let level: Int
    var query = ""

    private let library: Library

    var state: Library.State { library.state }

    init(level: Int, library: Library) {
        self.level = level
        self.library = library
    }

    func words(for mode: LevelMode) -> [Word] {
        mode == .words ? library.searchWords(query, level: level) : []
    }

    func characters(for mode: LevelMode) -> [Hanzi] {
        mode == .characters ? library.searchCharacters(query, level: level) : []
    }
}
