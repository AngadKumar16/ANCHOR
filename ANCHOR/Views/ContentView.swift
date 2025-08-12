//
//  ContentView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import SwiftUI

struct ContentView: View {
    @StateObject private var journalVM = JournalViewModel()
    @StateObject private var userVM = UserProfileViewModel()
    @StateObject private var riskVM = RiskAssessmentViewModel()

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Home", systemImage: "house") }
            JournalListView().environmentObject(journalVM)
                .tabItem { Label("Journal", systemImage: "book") }
            RiskAssessmentView()
                .environmentObject(riskVM)
                .tabItem { Label("Risk", systemImage: "exclamationmark.triangle") }
            SettingsView().environmentObject(userVM)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
