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
        }
    }
}

// MARK: - App State
class AppState: ObservableObject {
    // MARK: - Published Properties
    @Published var isAuthenticated = false
    @Published var photoLibraryAccess = false
    @Published var photoLibraryStatus: PHAuthorizationStatus = .notDetermined
    @Published var error: Error?
    
    // MARK: - Private Properties
    private var photoLibraryObserver: NSObjectProtocol?
    
    // MARK: - Initialization
    init() {
        checkPhotoLibraryAccess()
        setupPhotoLibraryObserver()
    }
    
    deinit {
        if let observer = photoLibraryObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    // MARK: - Private Methods
    private func checkPhotoLibraryAccess() {
        photoLibraryStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        photoLibraryAccess = photoLibraryStatus == .authorized
    }
    
    private func setupPhotoLibraryObserver() {
        photoLibraryObserver = NotificationCenter.default.addObserver(
            forName: PHPhotoLibrary.photoLibraryDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handlePhotoLibraryChange()
        }
    }
    
    private func handlePhotoLibraryChange() {
        checkPhotoLibraryAccess()
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
}

