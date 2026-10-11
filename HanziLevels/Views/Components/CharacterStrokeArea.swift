import SwiftUI

/// Detail metadata remains available while native stroke geometry is prepared independently.
@MainActor
struct CharacterStrokeArea: View {
    let character: Hanzi
    @Environment(Library.self) private var library
    @State private var prepared: PreparedStrokes?
    @State private var failed = false

    var body: some View {
        Group {
            if let prepared {
                StrokePlaybackView(characterID: character.id, strokes: prepared)
            } else if failed {
                ContentUnavailableView("Stroke order unavailable", systemImage: "pencil.tip.crop.circle.badge.exclamationmark",
                                       description: Text("The bundled strokes could not be read. Character information is still available below."))
            } else {
                ProgressView("Loading stroke order…")
                    .frame(maxWidth: .infinity, minHeight: 270)
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .task(id: character.id) {
            prepared = nil
            failed = false
            do {
                let result = try await library.preparedStrokes(for: character.id)
                try Task.checkCancellation()
                prepared = result
            } catch is CancellationError {
                // Navigation cancels the task; no error state is needed for a departed screen.
            } catch {
                if !Task.isCancelled { failed = true }
            }
        }
    }
}
