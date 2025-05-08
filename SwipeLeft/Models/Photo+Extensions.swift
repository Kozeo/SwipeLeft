import SwiftUI
import PhotosUI

extension Photo {
    // Load a thumbnail image synchronously
    func thumbnail(size: CGSize = CGSize(width: 200, height: 200)) -> UIImage? {
        let options = PHImageRequestOptions()
        options.deliveryMode = .fastFormat
        options.isSynchronous = true
        options.resizeMode = .exact
        
        var thumbnail: UIImage?
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            thumbnail = image
        }
        
        return thumbnail
    }
    
    // Load a full-sized image asynchronously
    func loadFullImage() async -> UIImage? {
        return await withCheckedContinuation { continuation in
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
                continuation.resume(returning: image)
            }
        }
    }
} 