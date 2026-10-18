import Foundation

enum CharacterLink {
    static func url(for id: String) -> URL? {
        guard id.count == 1 else { return nil }
        var components = URLComponents()
        components.scheme = "hanzilevels"
        components.host = "character"
        components.queryItems = [URLQueryItem(name: "id", value: id)]
        return components.url
    }

    static func characterID(from url: URL) -> String? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "hanzilevels", components.host == "character",
              components.path.isEmpty, components.user == nil, components.password == nil,
              components.port == nil, components.fragment == nil,
              let items = components.queryItems, items.count == 1,
              items[0].name == "id", let id = items[0].value, id.count == 1 else { return nil }
        return id
    }
}
