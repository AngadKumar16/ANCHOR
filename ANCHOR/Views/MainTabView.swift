//
//  MainTabView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI
import ANCHORFeatures_Dashboard

struct MainTabView: View {
    @StateObject private var journalViewModel = JournalViewModel()
    @StateObject private var riskAssessmentViewModel = RiskAssessmentViewModel()
    @StateObject private var userProfileViewModel = UserProfileViewModel()
    
    var body: some View {
        TabView {
            // Dashboard/Home Tab
            DashboardView()
                .environmentObject(journalViewModel)
                .environmentObject(riskAssessmentViewModel)
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            // Journal Tab
            NavigationView {
                JournalListView()
                    .environmentObject(journalViewModel)
            }
            .tabItem {
                Image(systemName: "book.fill")
                Text("Journal")
            }
            
            // Risk Assessment Tab
            RiskAssessmentView()
                .environmentObject(riskAssessmentViewModel)
                .tabItem {
                    Image(systemName: "shield.checkerboard")
                    Text("Assessment")
                }
            
            // Settings Tab
            NavigationView {
                SettingsView()
                    .environmentObject(userProfileViewModel)
            }
            .tabItem {
                Image(systemName: "gearshape.fill")
                Text("Settings")
            }
        }
        .accentColor(.blue)
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
