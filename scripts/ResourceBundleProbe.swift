import Foundation

/// Compiled with the production reader into a temporary macOS app bundle.
/// This verifies Bundle.main using Command Line Tools without UIKit or Xcode.
@main
struct ResourceBundleProbe {
    static func main() throws {
        let content = try BundledDataFiles.load()
        precondition(content.manifest.characterCount == 213)
        precondition(content.resources.count == 8)
        precondition(!content.manifest.releaseApproved)
        print("PASS: Bundle.main loaded 8 verified local resources (no networking APIs)")

        let temporary = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: temporary, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: temporary) }
        let original = Bundle.main.bundleURL
        let mutations = ["missing", "corrupt", "schema", "path", "approval", "license"]
        for mutation in mutations {
            let copy = temporary.appendingPathComponent("\(mutation).app")
            try FileManager.default.copyItem(at: original, to: copy)
            let data = copy.appendingPathComponent("Contents/Resources/Data")
            switch mutation {
            case "missing":
                try FileManager.default.removeItem(at: data.appendingPathComponent("characters.v1.json"))
            case "corrupt":
                try Data("[]".utf8).write(to: data.appendingPathComponent("words.v1.json"))
            case "license":
                try Data("changed".utf8).write(to: data.appendingPathComponent("Licenses/ARPHICPL.TXT"))
            default:
                let path = data.appendingPathComponent("manifest.json")
                var manifest = try JSONSerialization.jsonObject(with: Data(contentsOf: path)) as! [String: Any]
                if mutation == "schema" { manifest["schemaVersion"] = 2 }
                if mutation == "approval" { manifest["releaseApproved"] = true }
                if mutation == "path" {
                    var files = manifest["files"] as! [String: String]
                    files["../escape"] = String(repeating: "0", count: 64)
                    manifest["files"] = files
                }
                try JSONSerialization.data(withJSONObject: manifest).write(to: path)
            }
            guard let bundle = Bundle(url: copy) else { fatalError("Could not open fixture bundle") }
            do {
                _ = try BundledDataFiles.load(bundle: bundle)
                fatalError("Accepted invalid bundle: \(mutation)")
            } catch let error as BundledDataFiles.LoadError {
                switch (mutation, error) {
                case ("missing", .missingResource("characters.v1.json")),
                     ("corrupt", .corruptResource("words.v1.json")),
                     ("license", .corruptResource("Licenses/ARPHICPL.TXT")),
                     ("schema", .unsupportedSchema(2)),
                     ("path", .invalidManifest),
                     ("approval", .invalidManifest):
                    print("PASS: rejected \(mutation) fixture")
                default: fatalError("Unexpected error: \(error)")
                }
            }
        }
    }
}
