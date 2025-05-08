import Foundation

enum NetworkError: Error, LocalizedError {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case statusCode(Int)
    case decodingFailed(Error)
    case noData
    case unauthorized
    case serverError(String)
    case noInternet
    case timeout
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The URL provided was invalid."
        case .requestFailed(let error):
            return "The request failed: \(error.localizedDescription)"
        case .invalidResponse:
            return "The server returned an invalid response."
        case .statusCode(let code):
            return "The server returned status code \(code)."
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .noData:
            return "The server returned no data."
        case .unauthorized:
            return "You are not authorized to perform this action."
        case .serverError(let message):
            return "Server error: \(message)"
        case .noInternet:
            return "No internet connection available."
        case .timeout:
            return "The request timed out."
        case .unknown:
            return "An unknown error occurred."
        }
    }
} 