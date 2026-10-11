import SwiftUI

struct CharacterCard: View {
    let character: Hanzi
    @ScaledMetric(relativeTo: .largeTitle) private var hanziSize = 44

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(character.id)
                    .font(.system(size: hanziSize, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            Text(character.readings.joined(separator: " · "))
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
            Text(character.meaning)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
        .contentShape(.rect(cornerRadius: 14))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(character.id), \(character.readings.joined(separator: ", ")), \(character.meaning)")
        .accessibilityHint("Opens character details")
    }
}
