import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView {
            PhotoBrowserView()
                .tabItem {
                    Label("Browse", systemImage: "photo.stack")
                }
                .edgesIgnoringSafeArea([.top, .horizontal])
            
            PrivateCollectionView()
                .tabItem {
                    Label("Collection", systemImage: "heart.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .tint(.purple) // App's accent color
        .ignoresSafeArea(.keyboard) // Ignore keyboard safe area
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
} 