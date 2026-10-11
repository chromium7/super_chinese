enum LevelMode: String, CaseIterable, Identifiable {
    case words
    case characters

    var id: Self { self }

    var title: String {
        switch self {
        case .words: "Words"
        case .characters: "Characters"
        }
    }

    func resultLabel(count: Int) -> String {
        switch self {
        case .words: "\(count) \(count == 1 ? "word" : "words")"
        case .characters: "\(count) \(count == 1 ? "character" : "characters")"
        }
    }
}
