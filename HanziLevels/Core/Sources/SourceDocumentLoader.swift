import Foundation

/// Reads only local files off the main actor. A missing document does not hide the others.
actor SourceDocumentLoader {
    func load(directory: URL?) -> [SourceDocument: String] {
        guard let directory, directory.isFileURL else { return [:] }
        var documents: [SourceDocument: String] = [:]
        for document in SourceDocument.allCases {
            guard !Task.isCancelled else { return documents }
            let url = directory.appendingPathComponent(document.rawValue)
            guard let text = try? String(contentsOf: url, encoding: .utf8),
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }
            documents[document] = text
        }
        return documents
    }
}
