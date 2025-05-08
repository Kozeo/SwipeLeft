import Foundation
import UIKit

class NetworkService {
    // MARK: - Properties
    
    private let baseURL: URL
    private let session: URLSession
    private let authService: AuthService
    
    // Default configuration parameters
    private let defaultTimeout: TimeInterval = 30.0
    
    // MARK: - Initialization
    
    init(baseURLString: String, session: URLSession = .shared, authService: AuthService) {
        guard let url = URL(string: baseURLString) else {
            fatalError("Invalid base URL: \(baseURLString)")
        }
        self.baseURL = url
        self.session = session
        self.authService = authService
    }
    
    // MARK: - HTTP Methods
    
    /// Performs a GET request to the specified endpoint
    /// - Parameter endpoint: The API endpoint to request
    /// - Returns: The decoded response of the expected type
    func get<T: Decodable>(endpoint: String) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = defaultTimeout
        
        try await setAuthorizationHeader(for: &request)
        
        return try await performRequest(request)
    }
    
    /// Performs a POST request to the specified endpoint with the provided body
    /// - Parameters:
    ///   - endpoint: The API endpoint to request
    ///   - body: The body of the request to be encoded as JSON
    /// - Returns: The decoded response of the expected type
    func post<T: Decodable, U: Encodable>(endpoint: String, body: U) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = defaultTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode the request body
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        
        try await setAuthorizationHeader(for: &request)
        
        return try await performRequest(request)
    }
    
    /// Performs a PUT request to the specified endpoint with the provided body
    /// - Parameters:
    ///   - endpoint: The API endpoint to request
    ///   - body: The body of the request to be encoded as JSON
    /// - Returns: The decoded response of the expected type
    func put<T: Decodable, U: Encodable>(endpoint: String, body: U) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.timeoutInterval = defaultTimeout
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode the request body
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(body)
        
        try await setAuthorizationHeader(for: &request)
        
        return try await performRequest(request)
    }
    
    /// Performs a DELETE request to the specified endpoint
    /// - Parameter endpoint: The API endpoint to request
    /// - Returns: The decoded response of the expected type
    func delete<T: Decodable>(endpoint: String) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.timeoutInterval = defaultTimeout
        
        try await setAuthorizationHeader(for: &request)
        
        return try await performRequest(request)
    }
    
    /// Uploads an image to the specified endpoint
    /// - Parameters:
    ///   - endpoint: The API endpoint to upload to
    ///   - image: The image to upload
    ///   - metadata: Additional metadata to include with the upload
    /// - Returns: The decoded response of the expected type
    func uploadImage<T: Decodable>(endpoint: String, image: UIImage, metadata: [String: Any]) async throws -> T {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NetworkError.invalidResponse
        }
        
        return try await uploadData(endpoint: endpoint, data: imageData, filename: "photo.jpg", mimeType: "image/jpeg", metadata: metadata)
    }
    
    // MARK: - Helper Methods
    
    /// Performs a multipart form data upload
    /// - Parameters:
    ///   - endpoint: The API endpoint to upload to
    ///   - data: The data to upload
    ///   - filename: The filename for the uploaded data
    ///   - mimeType: The MIME type of the data
    ///   - metadata: Additional metadata to include with the upload
    /// - Returns: The decoded response of the expected type
    private func uploadData<T: Decodable>(endpoint: String, data: Data, filename: String, mimeType: String, metadata: [String: Any]) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = defaultTimeout
        
        // Generate boundary string for multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Create multipart form data
        var body = Data()
        
        // Add metadata fields
        for (key, value) in metadata {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        // Add the image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(mimeType)\r\n\r\n".data(using: .utf8)!)
        body.append(data)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add the closing boundary
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        // Set the body on the request
        request.httpBody = body
        
        try await setAuthorizationHeader(for: &request)
        
        return try await performRequest(request)
    }
    
    /// Sets the authorization header for the request if needed
    /// - Parameter request: The URLRequest to modify
    private func setAuthorizationHeader(for request: inout URLRequest) async throws {
        if let token = try? await authService.getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }
    
    /// Performs the actual network request and decodes the response
    /// - Parameter request: The URLRequest to perform
    /// - Returns: The decoded response of the expected type
    private func performRequest<T: Decodable>(_ request: URLRequest) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            // Handle status codes
            switch httpResponse.statusCode {
            case 200...299:
                // Success, continue processing
                break
            case 401:
                throw NetworkError.unauthorized
            case 400...499:
                throw NetworkError.statusCode(httpResponse.statusCode)
            case 500...599:
                throw NetworkError.serverError("Server returned status code \(httpResponse.statusCode)")
            default:
                throw NetworkError.unknown
            }
            
            // Debug logging in development
            #if DEBUG
            if let json = try? JSONSerialization.jsonObject(with: data, options: []) {
                print("Response: \(json)")
            }
            #endif
            
            // Decode the response
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            decoder.dateDecodingStrategy = .iso8601
            
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                print("Decoding error: \(error)")
                throw NetworkError.decodingFailed(error)
            }
        } catch let urlError as URLError {
            switch urlError.code {
            case .notConnectedToInternet:
                throw NetworkError.noInternet
            case .timedOut:
                throw NetworkError.timeout
            default:
                throw NetworkError.requestFailed(urlError)
            }
        } catch let networkError as NetworkError {
            throw networkError
        } catch {
            throw NetworkError.unknown
        }
    }
} 