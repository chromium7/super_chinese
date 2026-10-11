import SwiftUI

@MainActor
struct WordDetailView: View {
    let wordID: String
    @Environment(Library.self) private var library

    var body: some View {
        Group {
            if library.state == .ready, let word = library.word(id: wordID) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        DetailHeading(hanzi: word.id, pinyin: word.pinyin, meaning: word.english,
                                      levelLabel: "HSK \(word.level)")
                            .padding(.vertical, 20)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Characters")
                                .font(.headline)
                                .accessibilityAddTraits(.isHeader)
                            if word.uniqueCharacterIDs.isEmpty {
                                Text("No characters are listed for this word.")
                                    .foregroundStyle(.secondary)
                            } else {
                                LazyVGrid(columns: [GridItem(.flexible(), alignment: .top),
                                                    GridItem(.flexible(), alignment: .top)],
                                          alignment: .leading, spacing: 12) {
                                    ForEach(word.uniqueCharacterIDs, id: \.self) { id in
                                        if let character = library.character(id: id) {
                                            NavigationLink(value: Route.character(id)) {
                                                CharacterCard(character: character)
                                            }
                                            .buttonStyle(.plain)
                                        } else {
                                            Text("Character data unavailable for \(id).")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(20)
                }
                .background(Color(.systemGroupedBackground))
            } else {
                DetailUnavailableView(title: "Word unavailable", state: library.state)
            }
        }
        .navigationTitle(wordID)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Word · Light") {
    let library = Library()
    NavigationStack {
        WordDetailView(wordID: "学生")
    }
    .environment(library)
    .task { await library.load() }
    .preferredColorScheme(.light)
}

#Preview("Word · Dark · Accessibility") {
    let library = Library()
    NavigationStack {
        WordDetailView(wordID: "学生")
    }
    .environment(library)
    .task { await library.load() }
    .preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .accessibility3)
}
