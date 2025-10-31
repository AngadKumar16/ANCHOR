//
//  MainTabView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

struct MainTabView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var journalViewModel: JournalViewModel
    @StateObject private var riskAssessmentViewModel: RiskAssessmentViewModel
    @StateObject private var settingsViewModel: SettingsViewModel
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        let journalVM = JournalViewModel(context: context)
        let riskVM = RiskAssessmentViewModel(viewContext: context)
        let settingsVM = SettingsViewModel()
        
        _journalViewModel = StateObject(wrappedValue: journalVM)
        _riskAssessmentViewModel = StateObject(wrappedValue: riskVM)
        _settingsViewModel = StateObject(wrappedValue: settingsVM)
    }
    
    var body: some View {
        TabView {
            // Dashboard/Home Tab
            DashboardView()
                .environmentObject(journalViewModel)
                .environmentObject(riskAssessmentViewModel)
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            // Journal Tab
            NavigationView {
                JournalListView()
                    .environmentObject(journalViewModel)
            }
            .tabItem {
                Label("Journal", systemImage: "book.fill")
            }
            
            // Risk Assessment Tab
            RiskAssessmentView()
                .environmentObject(riskAssessmentViewModel)
                .tabItem {
                    Label("Risk", systemImage: "exclamationmark.triangle.fill")
                }
            
            // Settings Tab
            NavigationView {
                SettingsView()
                    .environmentObject(settingsViewModel)
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
        }
        .accentColor(Color.blue) // Set the accent color for selected tab
        .onAppear {
            // Customize the tab bar appearance
            let appearance = UITabBarAppearance()
            
            // Configure the default (unselected) tab bar appearance
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.systemBackground
            
            // Customize the selected tab item appearance
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(.blue)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: UIColor(.blue)]
            
            // Customize the unselected tab item appearance
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor.secondaryLabel
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.secondaryLabel]
            
            // Apply the appearance
            UITabBar.appearance().standardAppearance = appearance
            if #available(iOS 15.0, *) {
                UITabBar.appearance().scrollEdgeAppearance = appearance
            }
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
