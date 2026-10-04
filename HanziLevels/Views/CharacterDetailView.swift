import SwiftUI

struct CharacterDetailView: View {
    let characterID: String

    var body: some View {
        EmptyLibraryView(
            title: "Character unavailable",
            systemImage: "character.book.closed",
            description: "This character is not in the bundled library yet."
        )
        .navigationTitle(characterID)
        .navigationBarTitleDisplayMode(.inline)
    }
}
