import SwiftUI

/// The integration surface for stroke drawing and playback. Metadata browsing does not decode strokes.
struct CharacterStrokeArea: View {
    let character: Hanzi
    @ScaledMetric(relativeTo: .largeTitle) private var hanziSize = 96

    var body: some View {
        VStack(spacing: 16) {
            Text(character.id)
                .font(.system(size: hanziSize, weight: .regular))
                .minimumScaleFactor(0.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .frame(maxWidth: 270)
                .background(Color(.tertiarySystemGroupedBackground), in: .rect(cornerRadius: 16))
                .accessibilityHidden(true)
            Label("Stroke order", systemImage: "pencil.tip")
                .font(.headline)
            Text("Stroke playback is not available yet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }
}
