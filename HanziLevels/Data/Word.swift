import Foundation

struct Word: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let syllables: [String]
    let english: String
    let level: Int

    var characters: [String] { id.map(String.init) }
    var pinyin: String { PinyinFormatter.format(syllables) }
}
