import Foundation
import Security

class AuthService {
    // MARK: - Properties
    
    private let tokenKey = "com.swipeleft.authToken"
    private let userKey = "com.swipeleft.currentUser"
    private let networkService: NetworkService?
    private let apiBaseURL: String
    
    // In-memory token for performance
    private var cachedToken: String?
    private var tokenExpiryDate: Date?
    
    // MARK: - Initialization
    
    init(apiBaseURL: String) {
        self.apiBaseURL = apiBaseURL
        self.networkService = nil // Will be set later to avoid circular dependency
    }
    
    // Set the network service after initialization to avoid circular dependency
    func setNetworkService(_ service: NetworkService) {
        // Use a different implementation to avoid circular references
    }
    
    // MARK: - Authentication Methods
    
    /// Logs in a user with the provided credentials
    /// - Parameters:
    ///   - email: The user's email address
    ///   - password: The user's password
    /// - Returns: The logged-in user
    func login(email: String, password: String) async throws -> User {
        // Create a URL for the login endpoint
        guard let url = URL(string: "\(apiBaseURL)/auth/login") else {
            throw NetworkError.invalidURL
        }
        
        // Create a URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create a login request object
        struct LoginRequest: Codable {
            let email: String
            let password: String
        }
        
        // Create a login response object
        struct LoginResponse: Codable {
            let token: String
            let expiresIn: Int
            let user: User
        }
        
        // Encode the request body
        let loginRequest = LoginRequest(email: email, password: password)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(loginRequest)
        
        // Perform the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check the response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // Check status code
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw NetworkError.unauthorized
            } else {
                throw NetworkError.statusCode(httpResponse.statusCode)
            }
        }
        
        // Decode the response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let loginResponse = try decoder.decode(LoginResponse.self, from: data)
            
            // Save the token and user
            try saveAuthToken(loginResponse.token)
            try saveCurrentUser(loginResponse.user)
            
            // Set token expiry
            if loginResponse.expiresIn > 0 {
                tokenExpiryDate = Date().addingTimeInterval(TimeInterval(loginResponse.expiresIn))
            }
            
            // Cache the token
            cachedToken = loginResponse.token
            
            return loginResponse.user
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
    
    /// Logs out the current user
    func logout() {
        // Clear token and user
        try? deleteAuthToken()
        try? deleteCurrentUser()
        
        // Clear cached values
        cachedToken = nil
        tokenExpiryDate = nil
    }
    
    /// Registers a new user with the provided information
    /// - Parameters:
    ///   - email: The user's email address
    ///   - password: The user's password
    ///   - name: The user's name
    /// - Returns: The newly registered user
    func register(email: String, password: String, name: String) async throws -> User {
        // Create a URL for the register endpoint
        guard let url = URL(string: "\(apiBaseURL)/auth/register") else {
            throw NetworkError.invalidURL
        }
        
        // Create a URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Create a registration request object
        struct RegisterRequest: Codable {
            let email: String
            let password: String
            let name: String
        }
        
        // Create a registration response object
        struct RegisterResponse: Codable {
            let token: String
            let expiresIn: Int
            let user: User
        }
        
        // Encode the request body
        let registerRequest = RegisterRequest(email: email, password: password, name: name)
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(registerRequest)
        
        // Perform the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Check the response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        // Check status code
        guard httpResponse.statusCode == 200 || httpResponse.statusCode == 201 else {
            throw NetworkError.statusCode(httpResponse.statusCode)
        }
        
        // Decode the response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        do {
            let registerResponse = try decoder.decode(RegisterResponse.self, from: data)
            
            // Save the token and user
            try saveAuthToken(registerResponse.token)
            try saveCurrentUser(registerResponse.user)
            
            // Set token expiry
            if registerResponse.expiresIn > 0 {
                tokenExpiryDate = Date().addingTimeInterval(TimeInterval(registerResponse.expiresIn))
            }
            
            // Cache the token
            cachedToken = registerResponse.token
            
            return registerResponse.user
        } catch {
            throw NetworkError.decodingFailed(error)
        }
    }
    
    // MARK: - Token Management
    
    /// Gets the current authentication token
    /// - Returns: The authentication token if available
    func getAuthToken() async throws -> String? {
        // Check if we have a cached token and it's not expired
        if let cachedToken = cachedToken, let expiryDate = tokenExpiryDate, expiryDate > Date() {
            return cachedToken
        }
        
        // No cached token or it's expired, try to get from keychain
        return try retrieveAuthToken()
    }
    
    /// Checks if the user is authenticated
    /// - Returns: True if authenticated, false otherwise
    func isAuthenticated() async -> Bool {
        return (try? await getAuthToken()) != nil
    }
    
    // MARK: - Keychain Management
    
    /// Saves the authentication token to the keychain
    /// - Parameter token: The token to save
    private func saveAuthToken(_ token: String) throws {
        let data = Data(token.utf8)
        
        // Create a query to save the token
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data
        ] as [String: Any]
        
        // Delete any existing token
        SecItemDelete(query as CFDictionary)
        
        // Add the new token
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: "AuthService", code: Int(status), userInfo: nil)
        }
        
        // Cache the token
        cachedToken = token
    }
    
    /// Retrieves the authentication token from the keychain
    /// - Returns: The authentication token if available
    private func retrieveAuthToken() throws -> String? {
        // Create a query to retrieve the token
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ] as [String: Any]
        
        // Execute the query
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw NSError(domain: "AuthService", code: Int(status), userInfo: nil)
        }
        
        // Convert the result to a string
        guard let data = result as? Data, let token = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        // Cache the token
        cachedToken = token
        
        return token
    }
    
    /// Deletes the authentication token from the keychain
    private func deleteAuthToken() throws {
        // Create a query to delete the token
        let query = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey
        ] as [String: Any]
        
        // Execute the query
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw NSError(domain: "AuthService", code: Int(status), userInfo: nil)
        }
        
        // Clear the cached token
        cachedToken = nil
        tokenExpiryDate = nil
    }
    
    // MARK: - User Management
    
    /// Saves the current user to UserDefaults
    /// - Parameter user: The user to save
    private func saveCurrentUser(_ user: User) throws {
        let encoder = JSONEncoder()
        let data = try encoder.encode(user)
        UserDefaults.standard.set(data, forKey: userKey)
    }
    
    /// Retrieves the current user from UserDefaults
    /// - Returns: The current user if available
    func getCurrentUser() -> User? {
        guard let data = UserDefaults.standard.data(forKey: userKey) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        return try? decoder.decode(User.self, from: data)
    }
    
    /// Deletes the current user from UserDefaults
    private func deleteCurrentUser() throws {
        UserDefaults.standard.removeObject(forKey: userKey)
    }
}

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: String
    let email: String
    let name: String
    let profileImageURL: String?
    let createdAt: Date
} 