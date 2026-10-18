import SwiftUI

@MainActor
struct SourcesView: View {
    @State private var viewModel: SourcesViewModel

    init(viewModel: SourcesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

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
                        text: viewModel.documents?[document],
                        isLoading: viewModel.documents == nil,
                        retry: viewModel.retry
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Sources & Licenses")
        .navigationBarTitleDisplayMode(.large)
        .task(id: viewModel.reloadID) {
            if let missingCount = await viewModel.loadDocuments(), missingCount > 0 {
                AccessibilityNotification.Announcement("\(missingCount) bundled documents unavailable. Expand a document to retry.").post()
            }
        }
    }
}

#Preview("Light") {
    NavigationStack { SourcesView(viewModel: SourcesViewModel()) }
        .preferredColorScheme(.light)
}

#Preview("Dark · Accessibility") {
    NavigationStack { SourcesView(viewModel: SourcesViewModel()) }
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility3)
}
