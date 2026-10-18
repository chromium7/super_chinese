import SwiftUI

@MainActor
struct RootView: View {
    @Environment(Library.self) private var library
    @Binding var pendingCharacterID: String?
    @State private var path: [Route] = []

    init(pendingCharacterID: Binding<String?> = .constant(nil)) {
        _pendingCharacterID = pendingCharacterID
    }

    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .level(let level):
                        LevelView(level: level)
                    case .word(let id):
                        WordDetailView(wordID: id)
                    case .character(let id):
                        CharacterDetailView(characterID: id)
                    case .sources:
                        SourcesView()
                    case .history:
                        HistoryView()
                    }
                }
        }
        .onChange(of: pendingCharacterID, initial: true) { _, _ in openPendingCharacter() }
        .onChange(of: library.state) { _, _ in openPendingCharacter() }
    }

    private func openPendingCharacter() {
        guard library.state == .ready, let id = pendingCharacterID else { return }
        path = [.character(id)]
        pendingCharacterID = nil
    }
}

#Preview("Light") {
    let library = Library()
    RootView()
        .modelContainer(for: HistoryEntry.self, inMemory: true)
        .environment(library)
        .task { await library.load() }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    let library = Library()
    RootView()
        .modelContainer(for: HistoryEntry.self, inMemory: true)
        .environment(library)
        .task { await library.load() }
        .preferredColorScheme(.dark)
}
