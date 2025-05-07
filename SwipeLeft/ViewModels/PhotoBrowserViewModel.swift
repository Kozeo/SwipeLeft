import SwiftUI
import PhotosUI

@MainActor
class PhotoBrowserViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentPhoto: PHAsset?
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    private var photoFetchResult: PHFetchResult<PHAsset>?
    
    // MARK: - Initialization
    init() {
        loadPhotos()
    }
    
    // MARK: - Public Methods
    func loadPhotos() {
        isLoading = true
        
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        photoFetchResult = PHAsset.fetchAssets(with: .image, options: options)
        currentPhoto = photoFetchResult?.firstObject
        
        isLoading = false
    }
    
    func handleSwipe(direction: SwipeDirection) {
        switch direction {
        case .left:
            // Ignore photo
            moveToNextPhoto()
        case .right:
            // Save to private collection
            saveToPrivateCollection()
        case .up:
            // Upload to public feed
            uploadToPublicFeed()
        }
    }
    
    // MARK: - Private Methods
    private func moveToNextPhoto() {
        guard let currentIndex = photoFetchResult?.index(of: currentPhoto ?? PHAsset()) else { return }
        let nextIndex = currentIndex + 1
        
        if nextIndex < (photoFetchResult?.count ?? 0) {
            currentPhoto = photoFetchResult?.object(at: nextIndex)
        }
    }
    
    private func saveToPrivateCollection() {
        // TODO: Implement saving to private collection
        moveToNextPhoto()
    }
    
    private func uploadToPublicFeed() {
        // TODO: Implement uploading to public feed
        moveToNextPhoto()
    }
}

// MARK: - Supporting Types
enum SwipeDirection {
    case left
    case right
    case up
} 