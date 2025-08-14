//
//  AppRootView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

struct AppRootView: View {
    @StateObject private var appState = AppState()
    @State private var showingSplash = true
    
    var body: some View {
        Group {
            if showingSplash {
                SplashScreenView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showingSplash = false
                    }
                }
            } else if !appState.hasCompletedOnboarding {
                OnboardingView()
                    .environmentObject(appState)
            } else {
                MainTabView()
                    .environmentObject(appState)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: appState.hasCompletedOnboarding)
    }
}

#Preview {
    AppRootView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
