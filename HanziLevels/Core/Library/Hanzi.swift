import Foundation

struct Hanzi: Codable, Identifiable, Hashable, Sendable {
    let id: String
    let readings: [String]
    let meaning: String
    let strokeCount: Int
    let firstLevel: Int
}
