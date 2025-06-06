import SwiftUI
import PhotosUI

struct PhotoBrowserView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = PhotoBrowserViewModel(appState: AppState())
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(UIColor.systemBackground),
                        Color(UIColor.secondarySystemBackground)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    Spacer() // Add this spacer to push content down
                    
                    if !appState.photoLibraryAccess {
                        PhotoLibraryAccessView()
                    } else {
                        PhotoCardView()
                            .environmentObject(viewModel)
                    }
                }
            }
            .navigationTitle("Browse Photos")
            .navigationBarTitleDisplayMode(.inline)
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
                .tint(.purple)
            } else {
                Button("Grant Access") {
                    isRequestingAccess = true
                    Task {
                        await appState.requestPhotoLibraryAccess()
                        isRequestingAccess = false
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .disabled(isRequestingAccess)
            }
            
            if isRequestingAccess {
                ProgressView()
                    .padding(.top)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
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
