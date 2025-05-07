import SwiftUI
import PhotosUI

struct PhotoBrowserView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = PhotoBrowserViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                if !appState.photoLibraryAccess {
                    PhotoLibraryAccessView()
                } else {
                    PhotoCardView()
                        .environmentObject(viewModel)
                }
            }
            .navigationTitle("Browse Photos")
        }
    }
}

struct PhotoLibraryAccessView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Photo Access Required")
                .font(.title2)
                .bold()
            
            Text("Please allow access to your photo library to start swiping photos.")
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            Button("Grant Access") {
                PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
                    // Handle authorization status
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    PhotoBrowserView()
        .environmentObject(AppState())
} 