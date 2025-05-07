//
//  SwipeLeftApp.swift
//  SwipeLeft
//
//  Created by Elliot Gaubert on 07/05/2025.
//

import SwiftUI
import PhotosUI

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
    @Published var isAuthenticated = false
    @Published var photoLibraryAccess = false
    
    init() {
        checkPhotoLibraryAccess()
    }
    
    private func checkPhotoLibraryAccess() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        photoLibraryAccess = status == .authorized
    }
}

