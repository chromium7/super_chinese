import Foundation

struct SearchIndex: Sendable {
    private struct WordEntry: Sendable {
        let word: Word
        let pinyin: String
        let english: String
    }

    private struct CharacterEntry: Sendable {
        let hanzi: Hanzi
        let readings: [String]
        let meaning: String
    }

    private let words: [WordEntry]
    private let characters: [String: CharacterEntry]

    init(words: [Word], characters: [Hanzi]) {
        self.words = words.map {
            WordEntry(word: $0, pinyin: PinyinFormatter.normalize($0.pinyin), english: Self.normalizeMeaning($0.english))
        }
        self.characters = Dictionary(uniqueKeysWithValues: characters.map {
            ($0.id, CharacterEntry(hanzi: $0, readings: $0.readings.map(PinyinFormatter.normalize), meaning: Self.normalizeMeaning($0.meaning)))
        })
    }

    func searchWords(_ query: String, level: Int? = nil) -> [Word] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let pinyin = PinyinFormatter.normalize(text)
        let english = Self.normalizeMeaning(text)
        return words.filter { entry in
            (level == nil || entry.word.level == level) && (
                text.isEmpty || entry.word.id.contains(text)
                || (!pinyin.isEmpty && entry.pinyin.contains(pinyin))
                || entry.english.contains(english)
            )
        }.map(\.word)
    }

    func searchCharacters(_ query: String, ids: [String]) -> [Hanzi] {
        let text = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let reading = PinyinFormatter.normalize(text)
        let meaning = Self.normalizeMeaning(text)
        return ids.compactMap { id in
            guard let entry = characters[id],
                  text.isEmpty || id.contains(text)
                    || (!reading.isEmpty && entry.readings.contains(where: { $0.hasPrefix(reading) }))
                    || entry.meaning.contains(meaning) else { return nil }
            return entry.hanzi
        }
    }

    private static func normalizeMeaning(_ text: String) -> String {
        text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}
