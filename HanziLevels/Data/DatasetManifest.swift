import Foundation

struct DatasetManifest: Decodable, Sendable {
    let schemaVersion: Int
    let datasetVersion: String
    let files: [String: String]

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, datasetVersion, files
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schemaVersion = try values.decode(Int.self, forKey: .schemaVersion)
        guard schemaVersion == 1 else {
            throw LibraryError.unsupportedSchema(schemaVersion)
        }
        datasetVersion = try values.decode(String.self, forKey: .datasetVersion)
        files = try values.decode([String: String].self, forKey: .files)
        guard !datasetVersion.isEmpty,
              ["words.v1.json", "characters.v1.json", "strokes.v1.json"].allSatisfy({ files[$0] != nil }) else {
            throw LibraryError.invalidContent("The dataset manifest is incomplete.")
        }
    }
}
