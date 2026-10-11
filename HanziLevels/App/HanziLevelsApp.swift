import SwiftUI

@main
@MainActor
struct HanziLevelsApp: App {
    @State private var library = Library()

    var body: some Scene {
        WindowGroup {
            Group {
                if case .failed(let message) = library.state {
                    ContentUnavailableView("Content unavailable", systemImage: "exclamationmark.triangle", description: Text(message))
                } else {
                    RootView()
                }
            }
            .environment(library)
            .task { await library.load() }
        }
    }
}
