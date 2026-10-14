import SwiftUI

struct SourceDocumentView: View {
    let document: SourceDocument
    let text: String?
    let isLoading: Bool
    let retry: () -> Void
    @State private var isExpanded: Bool

    init(document: SourceDocument, text: String?, isLoading: Bool, retry: @escaping () -> Void) {
        self.document = document
        self.text = text
        self.isLoading = isLoading
        self.retry = retry
        _isExpanded = State(initialValue: document == .notes)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            Group {
                if isLoading {
                    ProgressView("Loading bundled text…")
                } else if let text {
                    Text(verbatim: text)
                        .font(.body)
                        .textSelection(.enabled)
                } else {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Document unavailable", systemImage: "exclamationmark.triangle")
                            .font(.headline)
                        Text("The bundled file \(document.rawValue) could not be read. This document is required before release.")
                            .font(.body)
                        Button("Retry", action: retry)
                            .buttonStyle(.bordered)
                            .frame(minHeight: 44)
                            .accessibilityLabel("Retry loading \(document.title)")
                    }
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 12)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(document.title)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if !isLoading && text == nil {
                    Label("Document unavailable", systemImage: "exclamationmark.triangle")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: 44, alignment: .leading)
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground), in: .rect(cornerRadius: 14))
    }
}
