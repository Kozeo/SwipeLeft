import Foundation

/// Represents the possible swipe directions in the photo browser
enum SwipeDirection {
    /// Swipe left to ignore the photo
    case left
    
    /// Swipe right to save to private collection
    case right
    
    /// Swipe up to upload to public feed
    case up
} 