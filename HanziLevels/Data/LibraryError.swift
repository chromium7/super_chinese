import Foundation

enum LibraryError: Error, LocalizedError, Equatable {
    case unsupportedSchema(Int)
    case invalidContent(String)
    case missingResources

    var errorDescription: String? {
        switch self {
        case .unsupportedSchema:
            "This bundled dataset version is not supported."
        case .invalidContent:
            "The bundled content could not be read."
        case .missingResources:
            "The bundled content is missing."
        }
    }
}
