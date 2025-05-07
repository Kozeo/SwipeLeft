//
//  ContentView.swift
//  SwipeLeft
//
//  Created by Elliot Gaubert on 07/05/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        MainTabView()
            .ignoresSafeArea()
            .environmentObject(appState)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
