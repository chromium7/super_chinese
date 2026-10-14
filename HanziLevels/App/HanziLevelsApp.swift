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
                    EmptyLibraryView(title: "Content unavailable", systemImage: "exclamationmark.triangle",
                                     description: "\(message) Try reopening the app. If the problem continues, an app update with corrected bundled content is needed.")
                } else if case .success(let container) = historyContainer {
                    RootView()
                        .modelContainer(container)
                } else {
                    ScrollView {
                        ContentUnavailableView {
                            Label("History unavailable", systemImage: "exclamationmark.triangle")
                        } description: {
                            Text("The history saved on this device could not be opened. Please try again.")
                        } actions: {
                            Button("Try Again") {
                                historyContainer = Result { try HistoryStore.makeContainer() }
                                if case .success = historyContainer {
                                    AccessibilityNotification.Announcement("History available.").post()
                                } else {
                                    AccessibilityNotification.Announcement("History could not be opened. Please try again.").post()
                                }
                            }
                            .buttonStyle(.bordered)
                            .frame(minHeight: 44)
                        }
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .environment(library)
            .task { await library.load() }
            .onChange(of: library.state) { _, state in
                switch state {
                case .loading:
                    break
                case .ready:
                    AccessibilityNotification.Announcement("Bundled library ready.").post()
                case .failed(let message):
                    AccessibilityNotification.Announcement("Content unavailable. \(message)").post()
                }
            }
        }
    }
}
