import Foundation

struct StrokeSet: Codable, Equatable, Sendable {
    let strokes: [String]
    let medians: [[[Double]]]

    func validate(expectedCount: Int) throws {
        guard strokes.count == expectedCount, medians.count == expectedCount,
              strokes.allSatisfy({ !$0.isEmpty }),
              medians.allSatisfy({ !$0.isEmpty && $0.allSatisfy {
                  $0.count == 2 && $0.allSatisfy(\.isFinite)
              } }) else {
            throw LibraryError.invalidContent("Invalid stroke data.")
        }
    }
}
