import Foundation
import ArgumentParser

enum APIError: Error {
    case notFound(String)
    case conflict(String)
    case validationFailed(String)
    case serverError(String)
    case connectionFailed
    case decodingError(Error)
    
    var message: String {
        switch self {
        case .notFound(let msg):
            return "Error: \(msg)"
        case .conflict(let msg):
            return "Error: \(msg)"
        case .validationFailed(let msg):
            return "Error: Validation failed.\n\(msg)"
        case .serverError(let msg):
            return "Error: \(msg)"
        case .connectionFailed:
            return "Error: Could not connect to server at http://localhost:8080.\nMake sure the server is running: swift run in swiftmarket-server/"
        case .decodingError(let err):
            return "Error: Decoding error: \(err.localizedDescription)"
        }
    }
}
