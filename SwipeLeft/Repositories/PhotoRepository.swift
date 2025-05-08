import Foundation
import PhotosUI

// Protocol defining operations for managing photos
protocol PhotoRepository {
    // Fetch operations
    func getPhoto(byId id: String) async throws -> Photo?
    func getAllPhotos() async throws -> [Photo]
    func getPhotos(withStatus status: PhotoStatus) async throws -> [Photo]
    
    // Status operations
    func updatePhotoStatus(id: String, newStatus: PhotoStatus) async throws
    func markAsIgnored(id: String) async throws
    func saveToPrivateCollection(id: String) async throws
    func uploadToPublicFeed(id: String) async throws
    
    // Collection operations
    func getPrivateCollection() async throws -> [Photo]
    func getPublicFeedPhotos() async throws -> [Photo]
    
    // Synchronization (if applicable)
    func syncPhotos() async throws
}

// Custom error types for photo operations
enum PhotoRepositoryError: Error {
    case photoNotFound
    case saveFailed
    case networkError(Error)
    case permissionDenied
    case serverError(String)
    case unknownError
    
    var localizedDescription: String {
        switch self {
        case .photoNotFound:
            return "The requested photo could not be found."
        case .saveFailed:
            return "Failed to save the photo information."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .permissionDenied:
            return "Permission denied to access photos."
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknownError:
            return "An unknown error occurred."
        }
    }
} 