import SwiftUI
import SwiftData

@MainActor
struct CharacterDetailView: View {
    let characterID: String
    @Environment(Library.self) private var library
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @Environment(\.modelContext) private var context
    @State private var showsHistoryError = false
    @State private var didAttemptHistoryRecord = false

    var body: some View {
        Group {
            if library.state == .ready, let character = library.character(id: characterID) {
                List {
                    Section {
                        CharacterStrokeArea(character: character)
                    }

                    Section {
                        DetailHeading(hanzi: character.id, pinyin: character.readings.joined(separator: " · "),
                                      meaning: character.meaning)
                            .padding(.vertical, 12)
                        metadata("Strokes", value: "\(character.strokeCount)")
                        metadata("First appears", value: "HSK \(character.firstLevel)")
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
                    guard !didAttemptHistoryRecord else { return }
                    didAttemptHistoryRecord = true
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

    @ViewBuilder
    private func metadata(_ title: String, value: String) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                Text(title).foregroundStyle(.secondary)
                Text(value)
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
        } else {
            LabeledContent(title, value: value)
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
