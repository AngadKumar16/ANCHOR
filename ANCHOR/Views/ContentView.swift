//
//  ContentView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/8/25.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0
    @State private var showingNewEntry = false
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content
            TabView(selection: $selectedTab) {
                // Dashboard View
                DashboardView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }
                    .tag(0)
                
                // Journal View
                JournalListView()
                    .tabItem {
                        Label("Journal", systemImage: "book.fill")
                    }
                    .tag(1)
                
                // Profile/More View
                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person.fill")
                    }
                    .tag(2)
            }
            .accentColor(ANCHORDesign.Colors.primary)
            
            // Floating Action Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { showingNewEntry = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        ANCHORDesign.Colors.primary,
                                        ANCHORDesign.Colors.accent
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(Circle())
                            .shadow(color: ANCHORDesign.Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                            .padding(.trailing, 24)
                            .padding(.bottom, 8)
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewEntry) {
            // New Entry View
            NavigationView {
                JournalEditorView()
                    .navigationTitle("New Entry")
                    .navigationBarItems(trailing: Button("Done") {
                        showingNewEntry = false
                    })
            }
        }
    }
}

// MARK: - Profile View
struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        NavigationView {
            List {
                // Profile Header
                VStack(spacing: 12) {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(ANCHORDesign.Colors.primary.opacity(0.8))
                    
                    Text("Welcome Back!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(ANCHORDesign.Colors.textPrimary)
                    
                    Text(authManager.currentUser?.email ?? "user@example.com")
                        .font(.subheadline)
                        .foregroundColor(ANCHORDesign.Colors.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .listRowBackground(Color.clear)
                .padding(.vertical, 20)
                
                // Stats
                Section(header: Text("Your Stats")) {
                    HStack {
                        StatView(value: "24", label: "Entries", icon: "book.fill", color: ANCHORDesign.Colors.primary)
                        Divider()
                        StatView(value: "7", label: "Week Streak", icon: "flame.fill", color: .orange)
                        Divider()
                        StatView(value: "90%", label: "Consistency", icon: "chart.bar.fill", color: .green)
                    }
                    .padding(.vertical, 8)
                }
                
                // Settings
                Section(header: Text("Settings")) {
                    NavigationLink(destination: Text("Account Settings")) {
                        Label("Account", systemImage: "person.crop.circle")
                    }
                    
                    NavigationLink(destination: Text("Notifications")) {
                        Label("Notifications", systemImage: "bell.badge")
                    }
                    
                    NavigationLink(destination: Text("Appearance")) {
                        Label("Appearance", systemImage: "paintpalette")
                    }
                    
                    NavigationLink(destination: Text("Help & Support")) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                }
                
                // Legal
                Section {
                    NavigationLink(destination: Text("Privacy Policy")) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    
                    NavigationLink(destination: Text("Terms of Service")) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                    
                    Button(action: { authManager.signOut() }) {
                        Label("Sign Out", systemImage: "arrow.left.square")
                            .foregroundColor(.red)
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Profile")
        }
    }
}

// MARK: - Stat View Component
struct StatView: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(value)
                    .font(.headline)
                    .foregroundColor(ANCHORDesign.Colors.textPrimary)
            }
            Text(label)
                .font(.caption)
                .foregroundColor(ANCHORDesign.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthManager())
            .environment(\.colorScheme, .light)
    }
}
