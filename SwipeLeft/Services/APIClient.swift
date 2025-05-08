import Foundation

// Mock API client for the RemotePhotoRepository
class APIClient {
    // MARK: - Properties
    private let baseURL: URL
    private let session: URLSession
    
    // MARK: - Initialization
    init(baseURLString: String = "https://api.swipeleft.com/v1", session: URLSession = .shared) {
        guard let url = URL(string: baseURLString) else {
            fatalError("Invalid base URL: \(baseURLString)")
        }
        self.baseURL = url
        self.session = session
    }
    
    // MARK: - API Methods
    
    func get(endpoint: String) async throws -> Any {
        // This is a stub implementation - would connect to a real API
        // Simulate network latency
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Return mock data based on endpoint
        switch endpoint {
        case "collections/private":
            return ["photoIds": []]
        default:
            return [:]
        }
    }
    
    func post(endpoint: String, body: [String: Any]) async throws {
        // Simulate network latency
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // In a real implementation, this would send the data to the server
        print("POST to \(endpoint) with body: \(body)")
    }
    
    func uploadPhoto(endpoint: String, imageData: Data, metadata: [String: Any]) async throws {
        // Simulate network latency and upload time
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        // In a real implementation, this would upload the image to the server
        print("Uploaded photo to \(endpoint) with \(imageData.count) bytes")
    }
} 