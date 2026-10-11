enum HistoryKind: String {
    case word
    case character

    var keyPrefix: String {
        switch self {
        case .word: "w:"
        case .character: "c:"
        }
    }
}
