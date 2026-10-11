/// Short source cards; the complete notices remain in bundled ATTRIBUTIONS.txt.
enum DataSourceAttribution: String, CaseIterable, Identifiable {
    case levels
    case definitions
    case strokes

    var id: Self { self }

    var role: String {
        switch self {
        case .levels: "Level lists"
        case .definitions: "Definitions & readings"
        case .strokes: "Stroke paths & medians"
        }
    }

    var name: String {
        switch self {
        case .levels: "Language Player / Zero to Hero Education"
        case .definitions: "CC-CEDICT"
        case .strokes: "Make Me a Hanzi"
        }
    }

    var note: String {
        switch self {
        case .levels:
            "Representative HSK 1–5 sample. No written redistribution permission or approved replacement was supplied. Release remains blocked until this decision is resolved."
        case .definitions:
            "Contributors and editor team, maintained by MDBG; original CEDICT by Paul Andrew Denisowski. Supplied definitions are shortened and subsetted. The original upstream revision was not supplied."
        case .strokes:
            "graphics.txt via hanzi-writer-data 2.0, derived from Arphic PL KaitiM GB and UKai. © 1999 Arphic Technology Co., Ltd. The supplied 213-character subset preserves paths and medians; modified data is available under the same license. No dictionary.txt is imported. The original upstream revision was not supplied."
        }
    }

    var license: String {
        switch self {
        case .levels: "No open license found; permission pending"
        case .definitions: SourceDocument.definitions.title
        case .strokes: SourceDocument.arphic.title
        }
    }
}
