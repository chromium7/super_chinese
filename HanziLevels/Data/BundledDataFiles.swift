import CryptoKit
import Foundation

/// Verifies local resources before Library decodes/indexes the vocabulary.
/// Call from a background task; reading and hashing the bundle is synchronous.
struct BundledDataFiles {
    struct Manifest: Decodable {
        let schemaVersion: Int
        let datasetVersion: String
        let files: [String: String]
        let sourceInputs: [String: String]
        let wordCounts: [Int]
        let characterCount: Int
        let releaseApproved: Bool
        let releaseBlockers: [String]
    }

    enum LoadError: LocalizedError {
        case missingResource(String)
        case unsupportedSchema(Int)
        case invalidManifest
        case corruptResource(String)

        var errorDescription: String? {
            switch self {
            case .missingResource(let name): "The bundled resource \(name) is missing."
            case .unsupportedSchema(let version): "Dataset schema \(version) is not supported."
            case .invalidManifest: "The bundled dataset manifest is invalid."
            case .corruptResource(let name): "The bundled resource \(name) failed its integrity check."
            }
        }
    }

    static let resourceNames: Set<String> = [
        "words.v1.json", "characters.v1.json", "strokes.v1.json",
        "manifest.schema.json", "Licenses/ARPHICPL.TXT",
        "Licenses/CC-BY-SA-3.0.txt", "Licenses/CC-BY-SA-4.0.txt", "Licenses/SOURCES.md"
    ]

    let manifest: Manifest
    let resources: [String: Data]

    /// The Data folder is a folder reference, retaining its Licenses directory.
    /// No fallback location, remote lookup, or silent recovery is used.
    static func load(bundle: Bundle = .main) throws -> Self {
        guard let directory = bundle.url(forResource: "Data", withExtension: nil) else {
            throw LoadError.missingResource("Data")
        }
        let manifestBytes = try read("manifest.json", in: directory)
        let manifest = try JSONDecoder().decode(Manifest.self, from: manifestBytes)
        guard manifest.schemaVersion == 1 else {
            throw LoadError.unsupportedSchema(manifest.schemaVersion)
        }
        let manifestKeys: Set<String> = [
            "schemaVersion", "datasetVersion", "files", "sourceInputs", "wordCounts",
            "characterCount", "releaseApproved", "releaseBlockers"
        ]
        let object = try JSONSerialization.jsonObject(with: manifestBytes) as? [String: Any]
        guard let object, Set(object.keys) == manifestKeys,
              manifest.datasetVersion == "2026.10.0-sample",
              Set(manifest.files.keys) == resourceNames,
              Set(manifest.sourceInputs.keys) == ["hsk.v1.json", "strokes.v1.json"],
              manifest.sourceInputs.values.allSatisfy(isHash),
              manifest.wordCounts == [71, 20, 16, 12, 12],
              manifest.characterCount == 213,
              !manifest.releaseApproved,
              manifest.releaseBlockers == [
                "Level-list written permission or approved replacement is missing.",
                "Original upstream definition and stroke revisions were not supplied."
              ] else {
            throw LoadError.invalidManifest
        }
        var resources: [String: Data] = [:]
        for name in resourceNames.sorted() {
            guard let expected = manifest.files[name], isHash(expected) else {
                throw LoadError.invalidManifest
            }
            let bytes = try read(name, in: directory)
            let actual = SHA256.hash(data: bytes).map { String(format: "%02x", $0) }.joined()
            guard actual == expected else { throw LoadError.corruptResource(name) }
            resources[name] = bytes
        }
        return Self(manifest: manifest, resources: resources)
    }

    private static func isHash(_ value: String) -> Bool {
        value.utf8.count == 64 && value.utf8.allSatisfy {
            (48...57).contains($0) || (97...102).contains($0)
        }
    }

    private static func read(_ name: String, in directory: URL) throws -> Data {
        let url = directory.appendingPathComponent(name)
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw LoadError.missingResource(name)
        }
        return try Data(contentsOf: url)
    }
}
