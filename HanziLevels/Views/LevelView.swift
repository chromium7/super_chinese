import SwiftUI

struct LevelView: View {
    let level: Int

    var body: some View {
        EmptyLibraryView(
            title: "No vocabulary yet",
            systemImage: "books.vertical",
            description: "Words and characters will appear here when the bundled library is available."
        )
        .navigationTitle("HSK \(level)")
        .navigationBarTitleDisplayMode(.large)
    }
}
