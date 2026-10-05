import SwiftUI

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
                    }
                }
        }
    }
}

#Preview("Light") {
    RootView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    RootView()
        .preferredColorScheme(.dark)
}
