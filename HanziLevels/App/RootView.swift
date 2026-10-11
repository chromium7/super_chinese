import SwiftUI

@MainActor
struct RootView: View {
    @State private var path: [Route] = []

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
