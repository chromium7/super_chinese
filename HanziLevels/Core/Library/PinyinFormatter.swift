import Foundation

enum PinyinFormatter {
    static func format(_ syllables: [String]) -> String {
        syllables.enumerated().map { index, syllable in
            let initial = syllable.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX")).first
            let separator = index > 0 && initial.map({ "aeo".contains($0) }) == true ? "'" : ""
            return separator + syllable
        }.joined()
    }

    static func normalize(_ text: String) -> String {
        // Preserve the umlaut before stripping tone marks, including decomposed input.
        let umlautPreserved = String(text.lowercased().precomposedStringWithCanonicalMapping.map { character in
            "üǖǘǚǜ".contains(character) ? Character("v") : character
        })
        return umlautPreserved.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .filter { !$0.isWhitespace && !"'’ʼ".contains($0) }
    }
}
