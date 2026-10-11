import SwiftUI

@MainActor
struct RootView: View {
    @State private var path: [Route] = []
    @State private var browsingState = BrowsingState()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .level(let level):
                        LevelView(level: level, mode: modeBinding(for: level))
                    case .word(let id):
                        WordDetailView(wordID: id)
                    case .character(let id):
                        CharacterDetailView(characterID: id)
                    case .sources:
                        SourcesView()
                    }
                }
        }
    }

    private func modeBinding(for level: Int) -> Binding<LevelMode> {
        Binding(
            get: { browsingState.modes[level, default: .words] },
            set: { browsingState.modes[level] = $0 }
        )
    }
}

#Preview("Light") {
    let library = Library()
    RootView()
        .environment(library)
        .task { await library.load() }
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    let library = Library()
    RootView()
        .environment(library)
        .task { await library.load() }
        .preferredColorScheme(.dark)
}
