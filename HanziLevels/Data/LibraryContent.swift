import Foundation

struct LibraryContent: Sendable {
    let manifest: DatasetManifest
    let words: [Word]
    let characters: [Hanzi]
    let wordsByID: [String: Word]
    let wordsByLevel: [Int: [Word]]
    let charactersByID: [String: Hanzi]
    let characterIDsByLevel: [Int: [String]]
    let wordsByCharacter: [String: [Word]]
    let strokeRecords: [String: Data]
    let searchIndex: SearchIndex

    init(manifest: Data, words: Data, characters: Data, strokes: Data) throws {
        let decoder = JSONDecoder()
        self.manifest = try decoder.decode(DatasetManifest.self, from: manifest)
        self.words = try decoder.decode([Word].self, from: words)
        self.characters = try decoder.decode([Hanzi].self, from: characters)
        guard Set(self.words.map(\.id)).count == self.words.count,
              Set(self.characters.map(\.id)).count == self.characters.count else {
            throw LibraryError.invalidContent("Duplicate content identifiers.")
        }
        wordsByID = Dictionary(uniqueKeysWithValues: self.words.map { ($0.id, $0) })
        charactersByID = Dictionary(uniqueKeysWithValues: self.characters.map { ($0.id, $0) })
        guard let rawStrokes = try JSONSerialization.jsonObject(with: strokes) as? [String: Any] else {
            throw LibraryError.invalidContent("Invalid stroke archive.")
        }
        // Keep serialized records; typed arrays and paths are decoded only on demand.
        strokeRecords = try rawStrokes.mapValues { record in
            guard let object = record as? [String: Any] else {
                throw LibraryError.invalidContent("Invalid stroke record.")
            }
            return try JSONSerialization.data(withJSONObject: object)
        }
        var levels: [Int: [Word]] = [:]
        var levelIDs: [Int: [String]] = [:]
        var relationships: [String: [Word]] = [:]
        var firstLevels: [String: Int] = [:]
        for word in self.words {
            guard !word.id.isEmpty, (1...5).contains(word.level),
                  word.syllables.count == word.characters.count,
                  word.syllables.allSatisfy({ !$0.isEmpty }), !word.english.isEmpty else {
                throw LibraryError.invalidContent("Invalid word fields.")
            }
            levels[word.level, default: []].append(word)
            var seenInWord: Set<String> = []
            for id in word.characters {
                guard charactersByID[id] != nil, strokeRecords[id] != nil else {
                    throw LibraryError.invalidContent("A word has missing character data.")
                }
                if !(levelIDs[word.level] ?? []).contains(id) {
                    levelIDs[word.level, default: []].append(id)
                }
                if seenInWord.insert(id).inserted { relationships[id, default: []].append(word) }
                firstLevels[id] = min(firstLevels[id] ?? word.level, word.level)
            }
        }
        for hanzi in self.characters {
            guard hanzi.id.count == 1, !hanzi.readings.isEmpty,
                  hanzi.readings.allSatisfy({ !$0.isEmpty }), !hanzi.meaning.isEmpty,
                  hanzi.strokeCount > 0, (1...5).contains(hanzi.firstLevel),
                  firstLevels[hanzi.id] == hanzi.firstLevel, strokeRecords[hanzi.id] != nil else {
                throw LibraryError.invalidContent("Invalid character fields or relationships.")
            }
        }
        wordsByLevel = levels
        characterIDsByLevel = levelIDs
        wordsByCharacter = relationships
        searchIndex = SearchIndex(words: self.words, characters: self.characters)
    }
}
