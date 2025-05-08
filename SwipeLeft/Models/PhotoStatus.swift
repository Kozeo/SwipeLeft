import Foundation

enum PhotoStatus: String, Codable {
    case unprocessed // Initial state when photo is loaded
    case ignored     // User swiped left
    case saved       // User swiped right (saved to private collection)
    case uploaded    // User swiped up (uploaded to public feed)
    
    // Add a helper property to determine if a photo has been processed
    var isProcessed: Bool {
        self != .unprocessed
    }
} 