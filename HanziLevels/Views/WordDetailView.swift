import SwiftUI

struct WordDetailView: View {
    let wordID: String

    var body: some View {
        EmptyLibraryView(
            title: "Word unavailable",
            systemImage: "text.book.closed",
            description: "This word is not in the bundled library yet."
        )
        .navigationTitle(wordID)
        .navigationBarTitleDisplayMode(.inline)
    }
}
