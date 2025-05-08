import Foundation

// This will be used for representing collections of photos, like "Private Collection"
struct PhotoCollection: Identifiable {
    let id: UUID
    let name: String
    var description: String?
    var photoIds: [String] // Store photo IDs rather than the photos themselves for persistence
    let dateCreated: Date
    var lastModified: Date
    
    init(id: UUID = UUID(), name: String, description: String? = nil, photoIds: [String] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.photoIds = photoIds
        self.dateCreated = Date()
        self.lastModified = self.dateCreated
    }
    
    // Add a photo ID to the collection
    mutating func addPhoto(id: String) {
        if !photoIds.contains(id) {
            photoIds.append(id)
            lastModified = Date()
        }
    }
    
    // Remove a photo ID from the collection
    mutating func removePhoto(id: String) {
        if let index = photoIds.firstIndex(of: id) {
            photoIds.remove(at: index)
            lastModified = Date()
        }
    }
    
    // Convenience function to check if a photo is in this collection
    func contains(photoId: String) -> Bool {
        return photoIds.contains(photoId)
    }
} 