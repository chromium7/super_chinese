import Foundation

/// Owned by the library so cached geometry is scoped to its bundled content.
actor StrokePathCache {
    private var paths: [String: PreparedStrokes] = [:]

    func prepare(characterID: String, record: Data, expectedCount: Int) throws -> PreparedStrokes {
        try Task.checkCancellation()
        if let cached = paths[characterID] { return cached }
        let strokes = try JSONDecoder().decode(StrokeSet.self, from: record)
        let prepared = try PreparedStrokes(strokes: strokes, expectedCount: expectedCount)
        try Task.checkCancellation()
        paths[characterID] = prepared
        return prepared
    }
}
