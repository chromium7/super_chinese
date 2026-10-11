import SwiftUI

struct CharacterDetailView: View {
    let characterID: String

    var body: some View {
        EmptyLibraryView(
            title: "Character details",
            systemImage: "character.book.closed",
            description: "Character details will be available in a later update."
        )
        .navigationTitle(characterID)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CharacterDetailView(characterID: "学")
    }
}
