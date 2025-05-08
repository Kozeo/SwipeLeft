import SwiftUI
import Photos

struct PhotoBrowserView: View {
    @StateObject private var viewModel: PhotoBrowserViewModel
    @State private var showPermissionAlert = false
    
    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: PhotoBrowserViewModel(appState: appState))
    }
    
    var body: some View {
        ZStack {
            // Background
            Theme.backgroundDark
                .ignoresSafeArea()
            
            if viewModel.isLoading {
                loadingView
            } else if viewModel.currentPhoto == nil {
                emptyStateView
            } else {
                mainContent
            }
        }
        .alert("Photo Access Required", isPresented: $showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please allow access to your photos to use SwipeLeft.")
        }
        .task {
            await viewModel.requestPhotoAccess()
        }
    }
    
    // MARK: - Main Content
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            // Status Bar
            statusBar
                .padding(.top, Theme.Layout.padding)
            
            // Photo Card
            if let photo = viewModel.currentPhoto {
                PhotoCardView(photo: photo) { direction in
                    Task {
                        await viewModel.handleSwipe(direction: direction)
                    }
                }
                .padding(.horizontal, Theme.Layout.padding)
                .padding(.vertical, Theme.Layout.smallPadding)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Status Bar
    
    private var statusBar: some View {
        HStack {
            // Photo Count
            Text("\(viewModel.currentIndex + 1)/\(viewModel.totalPhotos)")
                .font(Theme.Typography.captionFont)
                .foregroundColor(Theme.textSecondary)
            
            Spacer()
            
            // Settings Button
            Button {
                // TODO: Show settings
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: Theme.Layout.iconSize))
                    .foregroundColor(Theme.textSecondary)
            }
        }
        .padding(.horizontal, Theme.Layout.padding)
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: Theme.Layout.padding) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(Theme.textPrimary)
            
            Text("Loading Photos...")
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.textSecondary)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: Theme.Layout.padding) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 60))
                .foregroundColor(Theme.textSecondary)
            
            Text("No Photos Available")
                .font(Theme.Typography.headlineFont)
                .foregroundColor(Theme.textPrimary)
            
            Text("Add some photos to your library to get started.")
                .font(Theme.Typography.bodyFont)
                .foregroundColor(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Layout.padding)
            
            Button {
                showPermissionAlert = true
            } label: {
                Text("Check Permissions")
                    .font(Theme.Typography.bodyFont)
                    .foregroundColor(Theme.textPrimary)
                    .padding(.horizontal, Theme.Layout.padding)
                    .padding(.vertical, Theme.Layout.smallPadding)
                    .background(Theme.primaryGradient)
                    .cornerRadius(Theme.Layout.cornerRadius)
            }
            .padding(.top, Theme.Layout.padding)
        }
    }
}

#Preview {
    PhotoBrowserView(appState: AppState())
} 
