import SwiftUI

struct WordRow: View {
    let word: Word
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title2) private var hanziSize = 24

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(word.id)
                .font(.system(size: hanziSize))
                .foregroundStyle(.primary)
            Text(word.pinyin)
                .font(.subheadline)
                .foregroundStyle(Color.accentColor)
            Text(word.english)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Word: \(word.id), readings: \(word.pinyin), meaning: \(word.english)")
    }
}
