import Foundation
import XCTest

final class BundledDataFilesTests: XCTestCase {
    func testBundledDataHasCompleteCharacterCoverage() throws {
        let content = try BundledDataFiles.load(bundle: Bundle(for: Self.self))
        XCTAssertEqual(content.manifest.wordCounts, [71, 20, 16, 12, 12])
        XCTAssertFalse(content.manifest.releaseApproved)
        let words = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(content.resources["words.v1.json"])) as? [[String: Any]])
        let characters = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(content.resources["characters.v1.json"])) as? [[String: Any]])
        let strokes = try XCTUnwrap(JSONSerialization.jsonObject(with: XCTUnwrap(content.resources["strokes.v1.json"])) as? [String: [String: Any]])
        let byID = Dictionary(uniqueKeysWithValues: try characters.map { (try XCTUnwrap($0["id"] as? String), $0) })
        var firstLevels: [String: Int] = [:]
        for word in words {
            let id = try XCTUnwrap(word["id"] as? String)
            let level = try XCTUnwrap(word["level"] as? Int)
            XCTAssertEqual((word["syllables"] as? [String])?.count, id.count)
            for character in id.map(String.init) {
                firstLevels[character] = min(firstLevels[character] ?? level, level)
                let info = try XCTUnwrap(byID[character])
                let stroke = try XCTUnwrap(strokes[character])
                let count = try XCTUnwrap((stroke["strokes"] as? [String])?.count)
                XCTAssertEqual(info["strokeCount"] as? Int, count)
                XCTAssertEqual((stroke["medians"] as? [[[Double]]])?.count, count)
            }
        }
        XCTAssertEqual(Set(firstLevels.keys), Set(byID.keys))
        XCTAssertEqual(Set(firstLevels.keys), Set(strokes.keys))
        for (id, level) in firstLevels {
            XCTAssertEqual(byID[id]?["firstLevel"] as? Int, level)
        }
    }
}
