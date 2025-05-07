import SwiftUI
import PhotosUI

struct PhotoCardView: View {
    @EnvironmentObject private var viewModel: PhotoBrowserViewModel
    @State private var offset = CGSize.zero
    @State private var color: Color = .white
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer() // This pushes content down to the bottom
                
                // Photo content
                if let asset = viewModel.currentPhoto {
                    PhotoView(asset: asset)
                        .aspectRatio(contentMode: .fit) // Show entire image without cropping
                        .frame(width: geometry.size.width)
                        .padding(.bottom, 10) // Small padding above tab bar
                }
                
                // Swipe direction indicators
                HStack {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                        .opacity(Double(offset.width < 0 ? min(-offset.width/50, 1) : 0))
                    
                    Spacer()
                    
                    Image(systemName: "heart.fill")
                        .foregroundColor(.green)
                        .opacity(Double(offset.width > 0 ? min(offset.width/50, 1) : 0))
                }
                .padding(.horizontal, 40)
                
                // Upload indicator
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundColor(.blue)
                    .opacity(Double(offset.height < 0 ? min(-offset.height/50, 1) : 0))
                    .offset(y: -geometry.size.height/4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .offset(x: offset.width, y: offset.height)
            .rotationEffect(.degrees(Double(offset.width / 20)))
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        offset = gesture.translation
                        changeColor(width: offset.width, height: offset.height)
                    }
                    .onEnded { gesture in
                        withAnimation {
                            swipeCard(width: gesture.translation.width, height: gesture.translation.height)
                            changeColor(width: offset.width, height: offset.height)
                        }
                    }
            )
        }
        .edgesIgnoringSafeArea([.horizontal, .top])
    }
    
    private func swipeCard(width: CGFloat, height: CGFloat) {
        switch width {
        case -500...(-150):
            // Left swipe animation
            withAnimation(.easeOut(duration: 0.2)) {
                offset = CGSize(width: -500, height: 0)
            }
            
            // Process after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.viewModel.handleSwipe(direction: .left)
                
                // Reset position immediately for next card
                self.offset = CGSize(width: 500, height: 0)
                
                // Animate new card coming in from right
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.offset = .zero
                }
            }
            
        case 150...500:
            // Right swipe animation
            withAnimation(.easeOut(duration: 0.2)) {
                offset = CGSize(width: 500, height: 0)
            }
            
            // Process after animation completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.viewModel.handleSwipe(direction: .right)
                
                // Reset position immediately for next card
                self.offset = CGSize(width: -500, height: 0)
                
                // Animate new card coming in from left
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    self.offset = .zero
                }
            }
            
        default:
            if height < -150 {
                // Up swipe animation
                withAnimation(.easeOut(duration: 0.2)) {
                    offset = CGSize(width: 0, height: -500)
                }
                
                // Process after animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.viewModel.handleSwipe(direction: .up)
                    
                    // Reset position immediately for next card
                    self.offset = CGSize(width: 0, height: 500)
                    
                    // Animate new card coming in from bottom
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        self.offset = .zero
                    }
                }
            } else {
                // Return to center if swipe wasn't far enough
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    offset = .zero
                }
            }
        }
    }
    
    private func changeColor(width: CGFloat, height: CGFloat) {
        switch width {
        case -500...(-130):
            color = .red
        case 130...500:
            color = .green
        default:
            if height < -130 {
                color = .blue
            } else {
                color = .white
            }
        }
    }
}

private struct PhotoView: View {
    let asset: PHAsset
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                ProgressView()
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        do {
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat // Request high quality
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            
            // Track if continuation was already called
            var continuationCalled = false
            
            try await withCheckedThrowingContinuation { continuation in
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
                        continuation.resume(returning: ())
                        Task { @MainActor in
                            self.image = image
                        }
                    } else {
                        continuation.resume(throwing: PhotoError.loadFailed)
                    }
                }
            }
        } catch {
            print("Failed to load image: \(error)")
        }
    }
}

#Preview {
    PhotoCardView()
        .environmentObject(PhotoBrowserViewModel(appState: AppState()))
        .environmentObject(AppState())
} 
