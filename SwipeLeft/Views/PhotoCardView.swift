import SwiftUI
import PhotosUI

struct PhotoCardView: View {
    @EnvironmentObject private var viewModel: PhotoBrowserViewModel
    @State private var offset = CGSize.zero
    @State private var color: Color = .black
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let photo = viewModel.currentPhoto {
                    PhotoView(asset: photo)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .offset(x: offset.width, y: offset.height)
                        .rotationEffect(.degrees(Double(offset.width / 40)))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    offset = gesture.translation
                                    withAnimation {
                                        changeColor(width: offset.width)
                                    }
                                }
                                .onEnded { _ in
                                    withAnimation {
                                        swipeCard(width: offset.width, height: offset.height)
                                        changeColor(width: offset.width)
                                    }
                                }
                        )
                    
                    // Swipe direction indicators
                    HStack {
                        Image(systemName: "xmark")
                            .foregroundColor(.red)
                            .font(.system(size: 100))
                            .opacity(Double(offset.width < 0 ? -offset.width / 50 : 0))
                        
                        Spacer()
                        
                        Image(systemName: "heart.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 100))
                            .opacity(Double(offset.width > 0 ? offset.width / 50 : 0))
                    }
                    .padding(.horizontal, 40)
                    
                    // Upload indicator
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 100))
                        .opacity(Double(offset.height < 0 ? -offset.height / 50 : 0))
                        .offset(y: -geometry.size.height / 3)
                } else {
                    Text("No more photos")
                        .font(.title)
                        .foregroundColor(.gray)
                }
            }
        }
    }
    
    private func swipeCard(width: CGFloat, height: CGFloat) {
        switch width {
        case -500...(-150):
            offset = CGSize(width: -500, height: 0)
            viewModel.handleSwipe(direction: .left)
        case 150...500:
            offset = CGSize(width: 500, height: 0)
            viewModel.handleSwipe(direction: .right)
        default:
            if height < -150 {
                offset = CGSize(width: 0, height: -500)
                viewModel.handleSwipe(direction: .up)
            } else {
                offset = .zero
            }
        }
    }
    
    private func changeColor(width: CGFloat) {
        switch width {
        case -500...(-130):
            color = .red
        case 130...500:
            color = .green
        default:
            color = .black
        }
    }
}

struct PhotoView: View {
    let asset: PHAsset
    @State private var image: UIImage?
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        PHImageManager.default().requestImage(
            for: asset,
            targetSize: PHImageManagerMaximumSize,
            contentMode: .aspectFit,
            options: options
        ) { result, _ in
            self.image = result
        }
    }
}

#Preview {
    PhotoCardView()
        .environmentObject(PhotoBrowserViewModel())
} 