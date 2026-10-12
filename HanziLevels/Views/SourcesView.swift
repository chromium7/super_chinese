import SwiftUI

@MainActor
struct SourcesView: View {
    @State private var documents: [SourceDocument: String]?
    @State private var reloadID = 0
    private let loader = SourceDocumentLoader()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("Bundled data and its licenses are available on this device.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)

                ForEach(DataSourceAttribution.allCases) { source in
                    VStack(alignment: .leading, spacing: 10) {
                        Text(source.role)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Text(source.name)
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                        Text(source.note)
                            .font(.body)
                        Text("License: \(source.license)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
                    .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
                }

                Text("Bundled documents")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, 16)
                Text("Expand a document to read the full text. Source notes record the pending release decision and provenance gaps.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ForEach(SourceDocument.allCases) { document in
                    SourceDocumentView(
                        document: document,
                        text: documents?[document],
                        isLoading: documents == nil,
                        retry: retry
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Sources & Licenses")
        .navigationBarTitleDisplayMode(.large)
        .task(id: reloadID) { await loadDocuments() }
    }

    private func loadDocuments() async {
        let directory = Bundle.main.resourceURL?.appendingPathComponent("Data/Licenses", isDirectory: true)
        let loaded = await loader.load(directory: directory)
        guard !Task.isCancelled else { return }
        documents = loaded
        let missingCount = SourceDocument.allCases.filter { loaded[$0] == nil }.count
        if missingCount > 0 {
            AccessibilityNotification.Announcement("\(missingCount) bundled documents unavailable. Expand a document to retry.").post()
        }
    }

    private func retry() {
        documents = nil
        reloadID += 1
    }
}

#Preview("Light") {
    NavigationStack { SourcesView() }
        .preferredColorScheme(.light)
}

#Preview("Dark · Accessibility") {
    NavigationStack { SourcesView() }
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility3)
}
