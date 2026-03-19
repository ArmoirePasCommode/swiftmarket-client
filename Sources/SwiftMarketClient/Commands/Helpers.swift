import Foundation

func handleAPIError(_ error: Error) {
    if let apiErr = error as? APIError {
        printError(apiErr.message)
    } else {
        printError("Error: \(error.localizedDescription)")
    }
}

func printError(_ message: String) {
    fputs("\(message)\n", stderr)
}
