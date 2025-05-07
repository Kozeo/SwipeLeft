import SwiftUI
import PhotosUI

struct PhotoBrowserView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel: PhotoBrowserViewModel
    
    init() {
        // Initialize with a temporary AppState, will be replaced by environment object
        _viewModel = StateObject(wrappedValue: PhotoBrowserViewModel(appState: AppState()))
    }
    
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
        .onAppear {
            // Update ViewModel with the actual AppState from environment
            viewModel.updateAppState(appState)
        }
    }
}

struct PhotoLibraryAccessView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isRequestingAccess = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(accessTitle)
                .font(.title2)
                .bold()
            
            Text(accessMessage)
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
            
            if appState.photoLibraryStatus == .denied || appState.photoLibraryStatus == .restricted {
                Button("Open Settings") {
                    appState.openSettings()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Button("Grant Access") {
                    isRequestingAccess = true
                    Task {
                        await appState.requestPhotoLibraryAccess()
                        isRequestingAccess = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRequestingAccess)
            }
            
            if isRequestingAccess {
                ProgressView()
                    .padding(.top)
            }
        }
        .padding()
    }
    
    private var accessTitle: String {
        switch appState.photoLibraryStatus {
        case .denied:
            return "Photo Access Denied"
        case .restricted:
            return "Photo Access Restricted"
        case .limited:
            return "Limited Photo Access"
        default:
            return "Photo Access Required"
        }
    }
    
    private var accessMessage: String {
        switch appState.photoLibraryStatus {
        case .denied:
            return "Please enable photo access in Settings to use this feature."
        case .restricted:
            return "Photo access is restricted on this device."
        case .limited:
            return "You've granted limited access to your photos. You can change this in Settings."
        default:
            return "Please allow access to your photo library to start swiping photos."
        }
    }
}

#Preview {
    PhotoBrowserView()
        .environmentObject(AppState())
} 