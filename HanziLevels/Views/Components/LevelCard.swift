import SwiftUI

struct LevelCard: View {
    let level: Int
    let wordCount: Int
    let characterCount: Int
    let preview: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .title3) private var previewSize = 22

    var body: some View {
        HStack(spacing: 16) {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    summary
                    previewCharacters
                }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 16) {
                        summary
                        Spacer(minLength: 0)
                        previewCharacters
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        summary
                        previewCharacters
                    }
                }
            }
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .foregroundStyle(.primary)
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 16))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("HSK \(level), \(counts)")
        .accessibilityValue("Preview: \(preview)")
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("HSK \(level)")
                .font(.title3.weight(.semibold))
            Text(counts)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var counts: String {
        "\(LevelMode.words.resultLabel(count: wordCount)) · \(LevelMode.characters.resultLabel(count: characterCount))"
    }

    private var previewCharacters: some View {
        Text(preview)
            .font(.system(size: previewSize))
            .tracking(4)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
