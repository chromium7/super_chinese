import SwiftUI

@MainActor
struct LevelView: View {
    @State private var viewModel: LevelViewModel

    private var level: Int { viewModel.level }
    @AppStorage private var mode: LevelMode
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    init(viewModel: LevelViewModel) {
        _viewModel = State(initialValue: viewModel)
        _mode = AppStorage(wrappedValue: .words, BrowsingState.modeKey(for: viewModel.level))
    }

    var body: some View {
        let words = viewModel.words(for: mode)
        let characters = viewModel.characters(for: mode)
        let count = mode == .words ? words.count : characters.count

        VStack(alignment: .leading, spacing: 12) {
            Group {
                if dynamicTypeSize.isAccessibilitySize {
                    modePicker.pickerStyle(.menu)
                        .frame(minHeight: 44)
                } else {
                    modePicker.pickerStyle(.segmented)
                }
            }
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
                if viewModel.state == .loading {
                    ProgressView("Loading library…")
                } else if case .failed(let message) = viewModel.state {
                    EmptyLibraryView(title: "Library unavailable", systemImage: "exclamationmark.triangle",
                                     description: message)
                } else if count == 0 {
                    if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        EmptyLibraryView(title: "No \(mode.title.lowercased()) in this level",
                                         systemImage: "text.book.closed",
                                         description: "Choose another HSK level to browse the bundled content.")
                    } else {
                        ScrollView {
                            ContentUnavailableView.search(text: viewModel.query)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
        }
        .padding(.top, 12)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("HSK \(level)")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $viewModel.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Hanzi, pinyin or English")
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
    }

    private var modePicker: some View {
        Picker("Display mode", selection: $mode) {
            ForEach(LevelMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
    }
}

#Preview("Level · Light") {
    let library = Library()
    NavigationStack {
        LevelView(viewModel: LevelViewModel(level: 1, library: library))
    }
    .environment(library)
    .task { await library.load() }
    .preferredColorScheme(.light)
}

#Preview("Level · Dark") {
    let library = Library()
    NavigationStack {
        LevelView(viewModel: LevelViewModel(level: 1, library: library))
    }
    .environment(library)
    .task { await library.load() }
    .preferredColorScheme(.dark)
}

#Preview("Level · Accessibility") {
    let library = Library()
    NavigationStack {
        LevelView(viewModel: LevelViewModel(level: 1, library: library))
    }
    .environment(library)
    .task { await library.load() }
    .environment(\.dynamicTypeSize, .accessibility3)
}
