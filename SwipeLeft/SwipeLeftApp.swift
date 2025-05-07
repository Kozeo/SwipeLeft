//
//  SwipeLeftApp.swift
//  SwipeLeft
//
//  Created by Elliot Gaubert on 07/05/2025.
//

import SwiftUI
import PhotosUI
import Photos

@main
struct SwipeLeftApp: App {
    // MARK: - Properties
    @StateObject private var appState = AppState()
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .onAppear {
                    configureGlobalAppearance()
                }
        }
        .windowStyle(.automatic)
    }
    
    // MARK: - Private Methods
    private func configureGlobalAppearance() {
        // Configure global UI appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .systemBackground
        appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .systemBackground
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}

// MARK: - App State
class AppState: NSObject, ObservableObject, PHPhotoLibraryChangeObserver {
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var photoLibraryAccess = false
    @Published var photoLibraryStatus: PHAuthorizationStatus = .notDetermined
    @Published var error: Error?
    
    // MARK: - Private Properties
    private var currentPhotoIdentifier: String?
    
    // MARK: - Initialization
    override init() {
        super.init()
        checkPhotoLibraryAccess()
        PHPhotoLibrary.shared().register(self)
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    // MARK: - PHPhotoLibraryChangeObserver
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Check if the change affects our current photo
        if let currentIdentifier = currentPhotoIdentifier {
            let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [currentIdentifier], options: nil)
            if let changes = changeInstance.changeDetails(for: fetchResult) {
                // If our current photo was deleted or modified
                if changes.fetchResultAfterChanges.count == 0 {
                    checkPhotoLibraryAccess()
                }
            }
        } else {
            // If we don't have detailed change info, refresh everything
            checkPhotoLibraryAccess()
        }
    }
    
    // MARK: - Private Methods
    private func checkPhotoLibraryAccess() {
        photoLibraryStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        photoLibraryAccess = photoLibraryStatus == .authorized
    }
    
    // MARK: - Public Methods
    func requestPhotoLibraryAccess() async {
        do {
            let status = try await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            await MainActor.run {
                photoLibraryStatus = status
                photoLibraryAccess = status == .authorized
            }
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }
    
    func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    func setCurrentPhoto(_ asset: PHAsset?) {
        currentPhotoIdentifier = asset?.localIdentifier
    }
}

