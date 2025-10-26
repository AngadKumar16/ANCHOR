//
//  AppRootView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI
import os.log

struct AppRootView: View {
    @StateObject private var appState = AppState()
    @State private var showingSplash = true
    private let logger = OSLog(subsystem: "com.angadkumar16.ANCHOR", category: "AppRootView")
    
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
        .onAppear {
            os_log("🔍 AppRootView appeared", log: logger, type: .debug)
            os_log("📱 Onboarding status: %{public}@", 
                  log: logger, 
                  type: .debug, 
                  appState.hasCompletedOnboarding ? "Completed" : "Not completed")
            
            if showingSplash {
                os_log("🔄 Showing splash screen", log: logger, type: .debug)
            } else if !appState.hasCompletedOnboarding {
                os_log("👋 Showing onboarding view", log: logger, type: .debug)
            } else {
                os_log("🏠 Showing main tab view", log: logger, type: .debug)
            }
        }
        .onChange(of: showingSplash) { newValue in
            if !newValue {
                os_log("✅ Splash screen animation completed", log: logger, type: .debug)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showingSplash)
        .animation(.easeInOut(duration: 0.5), value: appState.hasCompletedOnboarding)
    }
}

#Preview {
    AppRootView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
