import SwiftUI

@MainActor
struct HistoryRow: View {
    let entry: HistoryEntry
    var showsChevron = false
    @Environment(Library.self) private var library

    var body: some View {
        if let route {
            NavigationLink(value: route) {
                HStack(spacing: 12) {
                    content
                    Spacer(minLength: 0)
                    if showsChevron {
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(.rect)
            }
        } else {
            content
        }
    }

    private var route: Route? {
        if entry.kind == HistoryKind.word.rawValue, library.word(id: entry.itemID) != nil {
            return .word(entry.itemID)
        }
        if entry.kind == HistoryKind.character.rawValue, library.character(id: entry.itemID) != nil {
            return .character(entry.itemID)
        }
        return nil
    }

    @ViewBuilder
    private var content: some View {
        if entry.kind == HistoryKind.word.rawValue, let word = library.word(id: entry.itemID) {
            WordRow(word: word)
        } else if entry.kind == HistoryKind.character.rawValue, let character = library.character(id: entry.itemID) {
            CharacterRow(character: character)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.itemID).font(.title2)
                Text("This item is no longer in the library.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
