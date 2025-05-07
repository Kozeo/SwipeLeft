import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        TabView {
            PhotoBrowserView()
                .tabItem {
                    Label("Browse", systemImage: "photo.stack")
                }
            
            PrivateCollectionView()
                .tabItem {
                    Label("Collection", systemImage: "heart.fill")
                }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
} 