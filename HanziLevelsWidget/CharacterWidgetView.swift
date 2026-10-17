import SwiftUI
import WidgetKit

struct CharacterWidgetView: View {
    let entry: CharacterEntry
    @Environment(\.widgetFamily) private var family
    @ScaledMetric(relativeTo: .largeTitle) private var characterSize = 52

    var body: some View {
        Group {
            if let character = entry.character {
                if family == .systemMedium {
                    HStack(spacing: 20) {
                        hanzi(character)
                            .frame(maxWidth: .infinity)
                        VStack(alignment: .leading, spacing: 8) {
                            level
                            reading(character)
                            meaning(character, lines: 3)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        level
                        hanzi(character)
                            .frame(maxWidth: .infinity)
                        reading(character)
                        meaning(character, lines: 1)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    level
                    Text("Character unavailable")
                        .font(.headline)
                    Text("Open Hanzi Levels to browse your library.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .containerBackground(.background, for: .widget)
        .widgetURL(entry.character.flatMap { CharacterLink.url(for: $0.id) })
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint(entry.character == nil ? "Opens Hanzi Levels" : "Opens character details")
    }

    private var level: some View {
        Text("HSK \(entry.level)")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }

    private func hanzi(_ character: Hanzi) -> some View {
        Text(character.id)
            .font(.system(size: characterSize, weight: .medium, design: .serif))
            .foregroundStyle(Color.accentColor)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }

    private func reading(_ character: Hanzi) -> some View {
        Text(character.readings.joined(separator: " · "))
            .font(.subheadline.weight(.medium))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    private func meaning(_ character: Hanzi, lines: Int) -> some View {
        Text(character.meaning)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(lines)
            .truncationMode(.tail)
    }

    private var accessibilitySummary: String {
        guard let character = entry.character else { return "HSK \(entry.level). Character unavailable." }
        return "HSK \(entry.level). \(character.id). \(character.readings.joined(separator: ", ")). \(character.meaning)"
    }
}

#Preview(as: .systemSmall) {
    HSKCharacterWidget()
} timeline: {
    CharacterEntry.sample
}

#Preview(as: .systemMedium) {
    HSKCharacterWidget()
} timeline: {
    CharacterEntry.sample
}
