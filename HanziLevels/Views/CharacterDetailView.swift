import SwiftUI
import SwiftData

@MainActor
struct CharacterDetailView: View {
    let characterID: String
    @Environment(Library.self) private var library

    @Environment(\.modelContext) private var context
    @State private var showsHistoryError = false

    var body: some View {
        Group {
            if library.state == .ready, let character = library.character(id: characterID) {
                List {
                    Section {
                        // APE-193 owns the stroke renderer and playback controls in this component.
                        CharacterStrokeArea(character: character)
                    }

                    Section {
                        DetailHeading(hanzi: character.id, pinyin: character.readings.joined(separator: " · "),
                                      meaning: character.meaning, levelLabel: "First appears in HSK \(character.firstLevel)")
                            .padding(.vertical, 12)
                        LabeledContent("Readings", value: character.readings.joined(separator: " · "))
                        LabeledContent("Strokes", value: "\(character.strokeCount)")
                        LabeledContent("First appears", value: "HSK \(character.firstLevel)")
                    }

                    Section("Appears in") {
                        let words = library.words(containing: character.id)
                        if words.isEmpty {
                            Text("No words in this library contain this character.")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(words) { word in
                                NavigationLink(value: Route.word(word.id)) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        WordRow(word: word)
                                        Text("HSK \(word.level)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .onAppear {
                    do { try HistoryStore.record(.character, itemID: characterID, in: context) }
                    catch { showsHistoryError = true }
                }
            } else {
                DetailUnavailableView(title: "Character unavailable", state: library.state)
            }
        }
        .navigationTitle(characterID)
        .navigationBarTitleDisplayMode(.inline)
        .alert("History could not be saved", isPresented: $showsHistoryError) {
        } message: {
            Text("You can keep browsing. Please reopen this item to try saving it again.")
        }
    }
}

#Preview("Character · Light") {
    let library = Library()
    NavigationStack {
        CharacterDetailView(characterID: "学")
    }
    .modelContainer(for: HistoryEntry.self, inMemory: true)
    .environment(library)
    .task { await library.load() }
    .preferredColorScheme(.light)
}

#Preview("Character · Dark · Accessibility") {
    let library = Library()
    NavigationStack {
        CharacterDetailView(characterID: "学")
    }
    .modelContainer(for: HistoryEntry.self, inMemory: true)
    .environment(library)
    .task { await library.load() }
    .preferredColorScheme(.dark)
    .environment(\.dynamicTypeSize, .accessibility3)
}
