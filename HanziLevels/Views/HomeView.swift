import SwiftUI

@MainActor
struct HomeView: View {
    @Environment(Library.self) private var library

    var body: some View {
        Group {
            switch library.state {
            case .loading:
                ProgressView("Loading library…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                ContentUnavailableView("Content unavailable", systemImage: "exclamationmark.triangle", description: Text(message))
            case .ready:
                levels
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Levels")
        .navigationBarTitleDisplayMode(.large)
    }

    private var levels: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("HSK 1–5 · words and characters")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)

                ForEach(1...5, id: \.self) { level in
                    NavigationLink(value: Route.level(level)) {
                        LevelCard(
                            level: level,
                            wordCount: library.words(in: level).count,
                            characterCount: library.characterIDs(in: level).count,
                            preview: library.words(in: level).prefix(3).compactMap { $0.characters.first }.joined()
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("level.\(level)")
                }

                // Recent stays hidden while history is empty; no placeholder records.
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

                Text("All content is stored on this device. Dataset \(library.datasetVersion ?? "Unknown")")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }
}
