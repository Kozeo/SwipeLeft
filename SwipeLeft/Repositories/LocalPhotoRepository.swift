import Foundation
import PhotosUI

class LocalPhotoRepository: PhotoRepository {
    // MARK: - Properties
    private let userDefaults: UserDefaults
    private let photoStatusKey = "com.swipeleft.photoStatus"
    private let privateCollectionKey = "com.swipeleft.privateCollection"
    
    // MARK: - Initialization
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    // MARK: - Private Methods
    
    // Save photo status dictionary to UserDefaults
    private func savePhotoStatuses(_ statusDict: [String: String]) throws {
        userDefaults.set(statusDict, forKey: photoStatusKey)
        
        // Verify the save was successful
        guard userDefaults.object(forKey: photoStatusKey) != nil else {
            throw PhotoRepositoryError.saveFailed
        }
    }
    
    // Load photo status dictionary from UserDefaults
    private func loadPhotoStatuses() -> [String: String] {
        return userDefaults.dictionary(forKey: photoStatusKey) as? [String: String] ?? [:]
    }
    
    // Save the collection of photo IDs
    private func savePhotoCollection(_ photoIds: [String], forKey key: String) throws {
        userDefaults.set(photoIds, forKey: key)
        
        // Verify the save was successful
        guard userDefaults.object(forKey: key) != nil else {
            throw PhotoRepositoryError.saveFailed
        }
    }
    
    // Load collection of photo IDs
    private func loadPhotoCollection(forKey key: String) -> [String] {
        return userDefaults.stringArray(forKey: key) ?? []
    }
    
    // Convert PHAsset to Photo with stored status
    private func createPhoto(from asset: PHAsset) -> Photo {
        let statuses = loadPhotoStatuses()
        let statusString = statuses[asset.localIdentifier]
        let status = statusString.flatMap { PhotoStatus(rawValue: $0) } ?? .unprocessed
        
        return Photo(
            id: asset.localIdentifier,
            asset: asset,
            status: status,
            dateAdded: Date()
        )
    }
    
    // MARK: - PhotoRepository Implementation
    
    func getPhoto(byId id: String) async throws -> Photo? {
        // Fetch the PHAsset with the given localIdentifier
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        guard let asset = fetchResult.firstObject else {
            return nil
        }
        
        return createPhoto(from: asset)
    }
    
    func getAllPhotos() async throws -> [Photo] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        var photos: [Photo] = []
        
        // Convert PHAssets to Photos with stored status
        fetchResult.enumerateObjects { asset, _, _ in
            photos.append(self.createPhoto(from: asset))
        }
        
        return photos
    }
    
    func getPhotos(withStatus status: PhotoStatus) async throws -> [Photo] {
        let allPhotos = try await getAllPhotos()
        return allPhotos.filter { $0.status == status }
    }
    
    func updatePhotoStatus(id: String, newStatus: PhotoStatus) async throws {
        var statuses = loadPhotoStatuses()
        statuses[id] = newStatus.rawValue
        try savePhotoStatuses(statuses)
        
        // If saving to private collection, also update that list
        if newStatus == .saved {
            var privateCollection = loadPhotoCollection(forKey: privateCollectionKey)
            if !privateCollection.contains(id) {
                privateCollection.append(id)
                try savePhotoCollection(privateCollection, forKey: privateCollectionKey)
            }
        }
    }
    
    func markAsIgnored(id: String) async throws {
        try await updatePhotoStatus(id: id, newStatus: .ignored)
    }
    
    func saveToPrivateCollection(id: String) async throws {
        try await updatePhotoStatus(id: id, newStatus: .saved)
    }
    
    func uploadToPublicFeed(id: String) async throws {
        try await updatePhotoStatus(id: id, newStatus: .uploaded)
        // Note: Actual uploading would be handled by RemotePhotoRepository
    }
    
    func getPrivateCollection() async throws -> [Photo] {
        let privateCollectionIds = loadPhotoCollection(forKey: privateCollectionKey)
        let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: privateCollectionIds, options: nil)
        
        var photos: [Photo] = []
        fetchResult.enumerateObjects { asset, _, _ in
            photos.append(self.createPhoto(from: asset))
        }
        
        return photos
    }
    
    func getPublicFeedPhotos() async throws -> [Photo] {
        // This would normally be handled by RemotePhotoRepository
        // For the local repository, we can just return photos marked as uploaded
        return try await getPhotos(withStatus: .uploaded)
    }
    
    func syncPhotos() async throws {
        // Local repository doesn't need to sync with remote
        // This would be implemented in a combined repository
    }
} 