import SwiftUI
import SwiftData

@main
@MainActor
struct HanziLevelsApp: App {
    @State private var library = Library()
    @State private var historyContainer = Result { try HistoryStore.makeContainer() }

    var body: some Scene {
        WindowGroup {
            Group {
                if case .failed(let message) = library.state {
                    ContentUnavailableView("Content unavailable", systemImage: "exclamationmark.triangle", description: Text(message))
                } else if case .success(let container) = historyContainer {
                    RootView()
                        .modelContainer(container)
                } else {
                    ContentUnavailableView {
                        Label("History unavailable", systemImage: "exclamationmark.triangle")
                    } description: {
                        Text("The history saved on this device could not be opened. Please try again.")
                    } actions: {
                        Button("Try Again") {
                            historyContainer = Result { try HistoryStore.makeContainer() }
                        }
                    }
                }
            }
            .environment(library)
            .task { await library.load() }
        }
    }
}
