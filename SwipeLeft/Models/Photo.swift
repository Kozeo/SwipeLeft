import Foundation
import PhotosUI

struct Photo: Identifiable, Equatable {
    // Core properties
    let id: String            // Use the PHAsset's localIdentifier as our ID
    let asset: PHAsset        // Reference to the underlying PHAsset
    var status: PhotoStatus   // Current status of the photo
    let dateAdded: Date       // When this photo was first processed by our app
    
    // Optional metadata
    var lastModified: Date?   // When this photo's status was last changed
    var localURL: URL?        // Local cache path if we're storing thumbnails
    
    // Initialize with a PHAsset, defaulting to unprocessed status
    init(asset: PHAsset, status: PhotoStatus = .unprocessed) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.status = status
        self.dateAdded = Date()
    }
    
    // Equatable implementation
    static func == (lhs: Photo, rhs: Photo) -> Bool {
        return lhs.id == rhs.id
    }
    
    // Helper property to get creation date from the asset
    var creationDate: Date? {
        return asset.creationDate
    }
    
    // Convert to a dictionary for storage
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "status": status.rawValue,
            "dateAdded": dateAdded
        ]
        
        if let lastModified = lastModified {
            dict["lastModified"] = lastModified
        }
        
        if let localURL = localURL {
            dict["localURL"] = localURL.absoluteString
        }
        
        return dict
    }
    
    // Create from a dictionary (for retrieval from storage)
    static func fromDictionary(_ dict: [String: Any], asset: PHAsset) -> Photo? {
        guard 
            let id = dict["id"] as? String,
            let statusRaw = dict["status"] as? String,
            let status = PhotoStatus(rawValue: statusRaw),
            let dateAdded = dict["dateAdded"] as? Date
        else {
            return nil
        }
        
        var photo = Photo(asset: asset)
        photo.id = id
        photo.status = status
        photo.dateAdded = dateAdded
        
        if let lastModified = dict["lastModified"] as? Date {
            photo.lastModified = lastModified
        }
        
        if let urlString = dict["localURL"] as? String, let url = URL(string: urlString) {
            photo.localURL = url
        }
        
        return photo
    }
    
    // Update status and set lastModified
    mutating func updateStatus(_ newStatus: PhotoStatus) {
        status = newStatus
        lastModified = Date()
    }
} 