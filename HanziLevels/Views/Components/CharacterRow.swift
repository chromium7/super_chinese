import SwiftUI

struct CharacterRow: View {
    let character: Hanzi
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title2) private var hanziSize = 24
    @ScaledMetric(relativeTo: .title2) private var tileSize = 44

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    tile
                    summary
                }
            } else {
                HStack(spacing: 12) {
                    tile
                    summary
                }
            }
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Character: \(character.id), readings: \(character.readings.joined(separator: ", ")), meaning: \(character.meaning), \(character.strokeCount) strokes")
    }

    private var tile: some View {
        Text(character.id)
            .font(.system(size: hanziSize))
            .foregroundStyle(.primary)
            .frame(width: tileSize, height: tileSize)
            .background(Color(.tertiarySystemGroupedBackground), in: .rect(cornerRadius: 10))
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(character.readings.joined(separator: " · "))
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
            Text(character.meaning)
                .font(.subheadline)
                .foregroundStyle(.primary)
            Text("\(character.strokeCount) \(character.strokeCount == 1 ? "stroke" : "strokes")")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}
