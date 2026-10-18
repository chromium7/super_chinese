import Foundation

struct Word: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let syllables: [String]
    let english: String
    let level: Int

    var characters: [String] { id.map(String.init) }
    var uniqueCharacterIDs: [String] {
        var seen: Set<String> = []
        return characters.filter { seen.insert($0).inserted }
    }
    var pinyin: String { PinyinFormatter.format(syllables) }
}
