import Observation

/// Session-only selection. Persisting preferences belongs to the history increment.
@MainActor
@Observable
final class BrowsingState {
    var modes: [Int: LevelMode] = [:]
}
