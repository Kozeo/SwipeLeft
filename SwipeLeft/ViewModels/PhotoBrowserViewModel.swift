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
    private var photoBuffer: [PHAsset] = []
    private var bufferSize = 4
    private var allPhotoIds: [String] = []  // Store only IDs, not actual assets
    private var usedIndices = Set<Int>()
    private let imageManager = PHImageManager.default()
    private var appState: AppState
    
    // MARK: - Initialization
    init(appState: AppState) {
        self.appState = appState
        loadInitialPhotos()
    }
    
    // MARK: - Public Methods
    func updateAppState(_ newAppState: AppState) {
        self.appState = newAppState
    }
    
    func loadInitialPhotos() {
        Task { @MainActor in
            isLoading = true
            
            // First, get just the IDs of all photos
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            // Extract just the identifiers to save memory
            allPhotoIds = []
            allPhotos.enumerateObjects { (asset, index, _) in
                self.allPhotoIds.append(asset.localIdentifier)
            }
            
            // Load initial buffer
            refreshPhotoBuffer()
            
            // Set current photo
            if !photoBuffer.isEmpty {
                currentPhoto = photoBuffer[0]
            }
            
            isLoading = false
        }
    }
    
    // MARK: - Buffer Management
    private func refreshPhotoBuffer() {
        // Only proceed if we have photos
        guard !allPhotoIds.isEmpty else { return }
        
        // Clear buffer if we've shown all photos
        if usedIndices.count >= allPhotoIds.count {
            usedIndices.removeAll()
        }
        
        // Fill buffer with new random photos
        while photoBuffer.count < bufferSize {
            // Get a truly random index we haven't used
            guard let randomIndex = getRandomUnusedIndex() else { break }
            
            // Fetch the actual asset
            let identifier = allPhotoIds[randomIndex]
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
            
            if let asset = fetchResult.firstObject {
                photoBuffer.append(asset)
            }
        }
        
        // Log buffer size for debugging
        print("Buffer now contains \(photoBuffer.count) photos")
    }
    
    // Helper method to get random unused index
    private func getRandomUnusedIndex() -> Int? {
        // If we've used all indices, return nil
        if usedIndices.count >= allPhotoIds.count {
            return nil
        }
        
        // Try to find unused index
        var attempts = 0
        var randomIndex: Int
        
        repeat {
            randomIndex = Int.random(in: 0..<allPhotoIds.count)
            attempts += 1
            
            // Prevent infinite loop
            if attempts > 100 {
                print("Warning: Too many attempts to find unused index")
                break
            }
        } while usedIndices.contains(randomIndex)
        
        // Mark as used
        usedIndices.insert(randomIndex)
        return randomIndex
    }
    
    // MARK: - Photo Navigation
    private func showNextPhoto() {
        // Remove the current photo from buffer
        if !photoBuffer.isEmpty {
            photoBuffer.removeFirst()
        }
        
        // Refresh buffer if needed
        refreshPhotoBuffer()
        
        // Set new current photo
        if !photoBuffer.isEmpty {
            currentPhoto = photoBuffer[0]
        }
    }
    
    // MARK: - Swipe Handlers
    func handleSwipe(direction: SwipeDirection) {
        Task { @MainActor in
            switch direction {
            case .left:
                // Ignore photo
                showNextPhoto()
            case .right:
                // Save to private collection
                saveToPrivateCollection()
            case .up:
                // Upload to public feed
                uploadToPublicFeed()
            }
        }
    }
    
    private func saveToPrivateCollection() {
        // TODO: Implement saving to private collection
        showNextPhoto()
    }
    
    private func uploadToPublicFeed() {
        // TODO: Implement uploading to public feed
        showNextPhoto()
    }
    
    // MARK: - Photo Loading
    func loadImage(for asset: PHAsset) async -> UIImage? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                let options = PHImageRequestOptions()
                options.deliveryMode = .highQualityFormat  // Request high quality
                options.isNetworkAccessAllowed = true
                options.isSynchronous = false
                
                // Track if continuation was already called
                var continuationCalled = false
                
                PHImageManager.default().requestImage(
                    for: asset,
                    targetSize: CGSize(width: UIScreen.main.bounds.width * 2, height: UIScreen.main.bounds.height * 2), // Request larger size
                    contentMode: .aspectFit,
                    options: options
                ) { image, info in
                    // Guard against calling continuation multiple times
                    guard !continuationCalled else { return }
                    continuationCalled = true
                    
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
            print("Image loading error: \(error)")
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