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
    private var preloadedImages: [String: UIImage] = [:] // Simple cache using asset ID as key
    private var bufferSize = 3
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
        Task {
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
            
            // Fill the buffer with random photos
            refreshPhotoBuffer()
            
            // Set the first one as current
            if !photoBuffer.isEmpty {
                await MainActor.run {
                    self.currentPhoto = photoBuffer[0]
                }
            }
            
            // Important: Preload images for all buffered photos
            preloadImagesForBuffer()
            
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
        if !photoBuffer.isEmpty {
            // Remove current photo
            photoBuffer.removeFirst()
            
            // Refresh buffer if needed
            refreshPhotoBuffer()
            
            // Update current photo
            Task { @MainActor in
                if !photoBuffer.isEmpty {
                    currentPhoto = photoBuffer[0]
                    print("New photo set: \(currentPhoto?.localIdentifier ?? "none")")
                }
            }
            
            // Preload the next ones right away
            preloadImagesForBuffer()
        }
    }
    
    // MARK: - Image Preloading
    private func preloadImagesForBuffer() {
        // Skip current photo (index 0) - it's already loading in the view
        for i in 1..<photoBuffer.count {
            let asset = photoBuffer[i]
            
            // Skip if already cached
            if preloadedImages[asset.localIdentifier] != nil {
                continue
            }
            
            // Background preloading
            Task {
                let image = await loadImage(for: asset)
                if let image = image {
                    preloadedImages[asset.localIdentifier] = image
                }
            }
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
        // First check cache
        if let cachedImage = preloadedImages[asset.localIdentifier] {
            return cachedImage
        }
        
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
                    targetSize: CGSize(width: UIScreen.main.bounds.width * 1.5, height: UIScreen.main.bounds.height * 1.5),
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
                        // Save to cache
                        self.preloadedImages[asset.localIdentifier] = image
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