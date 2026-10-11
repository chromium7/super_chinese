import SwiftUI

struct DetailHeading: View {
    let hanzi: String
    let pinyin: String
    let meaning: String
    let levelLabel: String
    @ScaledMetric(relativeTo: .largeTitle) private var hanziSize = 64

    var body: some View {
        VStack(spacing: 12) {
            Text(hanzi)
                .font(.system(size: hanziSize, weight: .medium))
                .accessibilityAddTraits(.isHeader)
            Text(pinyin)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
            Text(meaning)
                .font(.title3)
            Text(levelLabel)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(.tertiarySystemGroupedBackground), in: .capsule)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity)
    }
}
