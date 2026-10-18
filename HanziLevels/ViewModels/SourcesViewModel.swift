import Foundation
import Observation

@MainActor
@Observable
final class SourcesViewModel {
    private(set) var documents: [SourceDocument: String]?
    private(set) var reloadID = 0

    private let loader: SourceDocumentLoader

    init(loader: SourceDocumentLoader = SourceDocumentLoader()) {
        self.loader = loader
    }

    /// Returns the missing-document count for the view's accessibility announcement.
    /// A cancelled load leaves the current screen state unchanged.
    func loadDocuments(directory: URL? = Bundle.main.resourceURL?.appendingPathComponent("Data/Licenses", isDirectory: true)) async -> Int? {
        let loaded = await loader.load(directory: directory)
        guard !Task.isCancelled else { return nil }
        documents = loaded
        return SourceDocument.allCases.filter { loaded[$0] == nil }.count
    }

    func retry() {
        documents = nil
        reloadID += 1
    }
}
