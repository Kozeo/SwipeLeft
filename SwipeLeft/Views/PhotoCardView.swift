import SwiftUI
import PhotosUI

struct PhotoCardView: View {
    @EnvironmentObject private var viewModel: PhotoBrowserViewModel
    @State private var offset = CGSize.zero
    @State private var color: Color = .white
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background color to fill the entire screen
                Color(UIColor.systemBackground)
                    .ignoresSafeArea()
                
                // Photo content
                if let asset = viewModel.currentPhoto {
                    PhotoView(asset: asset)
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .clipped()
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
        .ignoresSafeArea(.all)
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

struct PhotoView: View {
    let asset: PHAsset
    @EnvironmentObject private var viewModel: PhotoBrowserViewModel
    @State private var image: UIImage?
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else if isLoading {
                ProgressView()
            }
        }
        .task {
            image = await viewModel.loadImage(for: asset)
            isLoading = false
        }
    }
}

#Preview {
    PhotoCardView()
        .environmentObject(PhotoBrowserViewModel(appState: AppState()))
        .environmentObject(AppState())
} 