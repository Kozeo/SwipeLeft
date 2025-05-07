import SwiftUI
import PhotosUI

// MARK: - Photo Error
enum PhotoError: Error {
    case assetNotFound
    case loadFailed
    case unauthorized
    case unknownError
}

@MainActor
class PhotoBrowserViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var currentPhoto: PHAsset? {
        didSet {
            appState.setCurrentPhoto(currentPhoto)
        }
    }
    @Published var isLoading = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    private var photoFetchResult: PHFetchResult<PHAsset>?
    private var appState: AppState
    
    // MARK: - Initialization
    init(appState: AppState) {
        self.appState = appState
        loadPhotos()
    }
    
    // MARK: - Public Methods
    func updateAppState(_ newAppState: AppState) {
        self.appState = newAppState
    }
    
    func loadPhotos() {
        Task { @MainActor in
            isLoading = true
            
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            photoFetchResult = PHAsset.fetchAssets(with: .image, options: options)
            if let firstAsset = photoFetchResult?.firstObject {
                currentPhoto = firstAsset
            }
            
            isLoading = false
        }
    }
    
    func handleSwipe(direction: SwipeDirection) {
        Task { @MainActor in
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
    }
    
    // MARK: - Private Methods
    private func moveToNextPhoto() {
        guard let currentPhoto = currentPhoto,
              let fetchResult = photoFetchResult else { return }
        
        let currentIndex = fetchResult.index(of: currentPhoto)
        let nextIndex = currentIndex + 1
        
        if nextIndex < fetchResult.count {
            self.currentPhoto = fetchResult.object(at: nextIndex)
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
    
    // MARK: - Photo Loading
    func loadImage(for asset: PHAsset) async -> UIImage? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat
                options.isNetworkAccessAllowed = true
                options.isSynchronous = false
                
                PHImageManager.default().requestImage(
                    for: asset,
                    targetSize: PHImageManagerMaximumSize,
                    contentMode: .aspectFit,
                    options: options
                ) { image, info in
                    if let error = info?[PHImageErrorKey] as? Error {
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    if let image = image {
                        continuation.resume(returning: image)
                    } else {
                        continuation.resume(throwing: PhotoError.loadFailed)
                    }
                }
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
            return nil
        }
    }
}

// MARK: - Supporting Types
enum SwipeDirection {
    case left
    case right
    case up
} 