import SwiftUI
import SwiftData
import WidgetKit

@MainActor
struct HomeView: View {
    @Environment(Library.self) private var library
    @Query(sort: HistoryStore.newestFirst) private var history: [HistoryEntry]
    @AppStorage(WidgetSettings.levelKey, store: WidgetSettings.defaults) private var currentLevel = 1

    var body: some View {
        Group {
            switch library.state {
            case .loading:
                ProgressView("Loading library…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .failed(let message):
                EmptyLibraryView(title: "Content unavailable", systemImage: "exclamationmark.triangle",
                                 description: message)
            case .ready:
                levels
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Levels")
        .navigationBarTitleDisplayMode(.large)
        .onChange(of: currentLevel) { _, _ in
            WidgetCenter.shared.reloadTimelines(ofKind: WidgetSettings.kind)
        }
    }

    private var levels: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("HSK 1–5 · words and characters")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)

                VStack(alignment: .leading, spacing: 4) {
                    Picker("Current HSK level", selection: $currentLevel) {
                        ForEach(1...5, id: \.self) { level in
                            Text("HSK \(level)").tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(minHeight: 44)
                    .accessibilityIdentifier("currentHSKLevel")
                    Text("Your Home Screen widget shows characters from this level.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
                .padding(.bottom, 12)
                .onAppear {
                    currentLevel = WidgetSettings.validLevel(currentLevel)
                }

                ForEach(1...5, id: \.self) { level in
                    NavigationLink(value: Route.level(level)) {
                        LevelCard(
                            level: level,
                            wordCount: library.words(in: level).count,
                            characterCount: library.characterIDs(in: level).count,
                            preview: library.previewCharacters(in: level)
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("level.\(level)")
                }

                if !history.isEmpty {
                    recent
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

                Text("All content is stored on this device. Dataset \(library.datasetVersion ?? "Unknown")")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
    }

    private var recent: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack {
                    recentTitle
                    Spacer(minLength: 12)
                    historyLink
                }
                VStack(alignment: .leading, spacing: 8) {
                    recentTitle
                    historyLink
                }
            }
            VStack(spacing: 0) {
                ForEach(Array(history.prefix(5))) { entry in
                    HistoryRow(entry: entry, showsChevron: true)
                        .buttonStyle(.plain)
                        .padding(16)
                    if entry.key != history.prefix(5).last?.key {
                        Divider().padding(.horizontal, 16)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
        }
        .padding(.top, 16)
    }

    private var recentTitle: some View {
        Text("Recent")
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
    }

    private var historyLink: some View {
        NavigationLink("See All", value: Route.history)
            .frame(minHeight: 44)
            .accessibilityLabel("See all history")
    }
}
