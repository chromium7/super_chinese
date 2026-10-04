import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("HSK 1–5 · words and characters")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)

                ForEach(1...5, id: \.self) { level in
                    NavigationLink(value: Route.level(level)) {
                        LevelCard(level: level)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("level.\(level)")
                }

                NavigationLink(value: Route.sources) {
                    HStack {
                        Text("Sources & Licenses")
                        Spacer(minLength: 16)
                        Image(systemName: "chevron.right")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .accessibilityHidden(true)
                    }
                    .foregroundStyle(.primary)
                    .padding(20)
                    .frame(minHeight: 44)
                    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.top, 16)
                .accessibilityIdentifier("sources")

                Text("All content is stored on this device. No dataset bundled yet.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Levels")
        .navigationBarTitleDisplayMode(.large)
    }
}
