/// Item identifiers are hanzi, matching the future bundled library.
enum Route: Hashable {
    case level(Int)
    case word(String)
    case character(String)
    case sources
}
