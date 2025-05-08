import SwiftUI
import Photos

struct PhotoCardView: View {
    let photo: Photo
    let onSwipe: (SwipeDirection) -> Void
    
    @State private var offset = CGSize.zero
    @State private var rotation: Double = 0
    @State private var swipeOpacity: Double = 0
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Photo View
                PhotoView(photo: photo)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .cornerRadius(Theme.Layout.cornerRadius)
                    .shadow(radius: 10)
                
                // Swipe Direction Overlays
                swipeOverlays
                
                // Status Text
                VStack {
                    Spacer()
                    Text(swipeStatusText)
                        .font(Theme.Typography.captionFont)
                        .foregroundColor(Theme.textPrimary)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(Theme.Layout.cornerRadius)
                        .padding(.bottom, Theme.Layout.padding)
                }
            }
            .offset(x: offset.width, y: offset.height)
            .rotationEffect(.degrees(rotation))
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        handleDragGesture(gesture, in: geometry)
                    }
                    .onEnded { gesture in
                        handleDragEnd(gesture, in: geometry)
                    }
            )
        }
    }
    
    // MARK: - Swipe Overlays
    
    private var swipeOverlays: some View {
        ZStack {
            // Left Swipe (Ignore)
            Theme.swipeLeftGradient
                .opacity(swipeOpacity * (offset.width < 0 ? 1 : 0))
                .overlay(
                    Image(systemName: "xmark")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                )
            
            // Right Swipe (Save)
            Theme.swipeRightGradient
                .opacity(swipeOpacity * (offset.width > 0 ? 1 : 0))
                .overlay(
                    Image(systemName: "heart.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                )
            
            // Up Swipe (Upload)
            Theme.swipeUpGradient
                .opacity(swipeOpacity * (offset.height < 0 ? 1 : 0))
                .overlay(
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                )
        }
    }
    
    // MARK: - Helper Methods
    
    private var swipeStatusText: String {
        if offset.width < -Theme.Layout.swipeThreshold {
            return "Ignore"
        } else if offset.width > Theme.Layout.swipeThreshold {
            return "Save to Collection"
        } else if offset.height < -Theme.Layout.swipeThreshold {
            return "Upload to Feed"
        }
        return "Swipe to interact"
    }
    
    private func handleDragGesture(_ gesture: DragGesture.Value, in geometry: GeometryProxy) {
        offset = gesture.translation
        
        // Calculate rotation based on horizontal movement
        rotation = Double(gesture.translation.width / 20)
        
        // Calculate swipe opacity based on distance from center
        let horizontalDistance = abs(gesture.translation.width)
        let verticalDistance = abs(gesture.translation.height)
        swipeOpacity = min(max(horizontalDistance, verticalDistance) / Theme.Layout.swipeThreshold, 1.0)
    }
    
    private func handleDragEnd(_ gesture: DragGesture.Value, in geometry: GeometryProxy) {
        let horizontalDistance = abs(gesture.translation.width)
        let verticalDistance = abs(gesture.translation.height)
        
        withAnimation(Theme.Animation.spring) {
            if horizontalDistance > Theme.Layout.swipeThreshold {
                // Horizontal swipe
                if gesture.translation.width > 0 {
                    // Right swipe - Save
                    offset.width = geometry.size.width * 1.5
                    onSwipe(SwipeDirection.right)
                } else {
                    // Left swipe - Ignore
                    offset.width = -geometry.size.width * 1.5
                    onSwipe(SwipeDirection.left)
                }
            } else if verticalDistance > Theme.Layout.swipeThreshold && gesture.translation.height < 0 {
                // Up swipe - Upload
                offset.height = -geometry.size.height * 1.5
                onSwipe(SwipeDirection.up)
            } else {
                // Reset position
                offset = .zero
                rotation = 0
                swipeOpacity = 0
            }
        }
    }
}

// MARK: - Photo View

private struct PhotoView: View {
    let photo: Photo
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Theme.primaryGradient
                    .opacity(0.3)
            }
            
            if isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(Theme.textPrimary)
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let manager = PHImageManager.default()
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            
            let screenSize = UIScreen.main.bounds.size
            let targetSize = CGSize(
                width: screenSize.width * 2,
                height: screenSize.height * 2
            )
            
            var continuationCalled = false
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                manager.requestImage(
                    for: photo.asset,
                    targetSize: targetSize,
                    contentMode: .aspectFit,
                    options: options
                ) { result, info in
                    if !continuationCalled {
                        continuationCalled = true
                        
                        if let error = info?[PHImageErrorKey] as? Error {
                            continuation.resume(throwing: error)
                            return
                        }
                        
                        if let result = result {
                            self.image = result
                            continuation.resume()
                        } else {
                            continuation.resume(throwing: NSError(domain: "PhotoView", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to load image"]))
                        }
                    }
                }
            }
        } catch {
            print("Error loading image: \(error)")
        }
    }
}

#Preview {
    PhotoCardView(photo: Photo(asset: PHAsset()), onSwipe: { _ in })
} 
