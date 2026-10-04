import SwiftUI

struct SourcesView: View {
    var body: some View {
        EmptyLibraryView(
            title: "No sources bundled yet",
            systemImage: "doc.text",
            description: "Source attributions and license texts will appear here alongside the bundled vocabulary."
        )
        .navigationTitle("Sources & Licenses")
        .navigationBarTitleDisplayMode(.large)
    }
}
