enum SourceDocument: String, CaseIterable, Identifiable, Sendable {
    case notes = "ATTRIBUTIONS.txt"
    case arphic = "ARPHICPL.TXT"
    case definitions = "CC-BY-SA-3.0.txt"

    var id: Self { self }

    var title: String {
        switch self {
        case .notes: "Source notes & release status"
        case .arphic: "Arphic Public License"
        case .definitions: "CC BY-SA 3.0 Unported"
        }
    }
}
