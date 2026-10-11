import SwiftUI

struct WordDetailView: View {
    let wordID: String

    var body: some View {
        EmptyLibraryView(
            title: "Word details",
            systemImage: "text.book.closed",
            description: "Word details will be available in a later update."
        )
        .navigationTitle(wordID)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        WordDetailView(wordID: "学生")
    }
}
