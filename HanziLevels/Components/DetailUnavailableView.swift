import SwiftUI

@MainActor
struct DetailUnavailableView: View {
    let title: String
    let state: Library.State

    var body: some View {
        Group {
            switch state {
            case .loading:
                ProgressView("Loading library…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemGroupedBackground))
            case .failed(let message):
                EmptyLibraryView(title: "Library unavailable", systemImage: "exclamationmark.triangle",
                                 description: message)
            case .ready:
                EmptyLibraryView(title: title, systemImage: "text.book.closed",
                                 description: "This item is not included in the bundled library.")
            }
        }
    }
}
