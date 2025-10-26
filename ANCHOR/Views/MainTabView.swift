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
    @StateObject private var userProfileViewModel: UserProfileViewModel
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        let journalVM = JournalViewModel(context: context)
        let riskVM = RiskAssessmentViewModel(viewContext: context)
        let userProfileVM = UserProfileViewModel(viewContext: context)
        
        _journalViewModel = StateObject(wrappedValue: journalVM)
        _riskAssessmentViewModel = StateObject(wrappedValue: riskVM)
        _userProfileViewModel = StateObject(wrappedValue: userProfileVM)
    }
    
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
