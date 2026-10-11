import SwiftUI

@MainActor
struct LevelView: View {
    let level: Int
    @Binding var mode: LevelMode
    @Environment(Library.self) private var library
    @State private var query = ""

    var body: some View {
        let words = mode == .words ? library.searchWords(query, level: level) : []
        let characters = mode == .characters ? library.searchCharacters(query, level: level) : []
        let count = mode == .words ? words.count : characters.count

        VStack(alignment: .leading, spacing: 12) {
            Picker("Display mode", selection: $mode) {
                ForEach(LevelMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            .accessibilityIdentifier("level.mode")

            Text(mode.resultLabel(count: count))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
                .accessibilityIdentifier("level.resultCount")

            List {
                if mode == .words {
                    ForEach(words) { word in
                        NavigationLink(value: Route.word(word.id)) {
                            WordRow(word: word)
                        }
                    }
                } else {
                    ForEach(characters) { character in
                        NavigationLink(value: Route.character(character.id)) {
                            CharacterRow(character: character)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .contentMargins(.top, 0, for: .scrollContent)
            .overlay {
                if library.state == .loading {
                    ProgressView("Loading library…")
                } else if count == 0 {
                    ContentUnavailableView.search(text: query)
                }
            }
        }
        .padding(.top, 12)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("HSK \(level)")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Hanzi, pinyin or English")
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
    }
}

#Preview("Words · Light") {
    let library = Library()
    NavigationStack {
        LevelView(level: 1, mode: .constant(.words))
    }
    .environment(library)
    .task { await library.load() }
    .preferredColorScheme(.light)
}

#Preview("Characters · Dark") {
    let library = Library()
    NavigationStack {
        LevelView(level: 1, mode: .constant(.characters))
    }
    .environment(library)
    .task { await library.load() }
    .preferredColorScheme(.dark)
}

#Preview("Characters · Accessibility") {
    let library = Library()
    NavigationStack {
        LevelView(level: 1, mode: .constant(.characters))
    }
    .environment(library)
    .task { await library.load() }
    .environment(\.dynamicTypeSize, .accessibility3)
}
