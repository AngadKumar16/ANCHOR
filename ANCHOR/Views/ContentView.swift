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
    @StateObject private var journalVM = JournalViewModel()
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content with custom background
            LinearGradient(
                gradient: Gradient(colors: [
                    ANCHORDesign.Colors.backgroundPrimary,
                    ANCHORDesign.Colors.backgroundSecondary
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Main content
            TabView(selection: $selectedTab) {
                // Dashboard View
                DashboardView()
                    .tag(0)
                    .hideNavigationBar()
                
                // Journal View
                JournalListView()
                    .tag(1)
                    .hideNavigationBar()
                
                // Profile/More View
                ProfileView()
                    .tag(2)
                    .hideNavigationBar()
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .overlay(
                // Custom Tab Bar
                VStack(spacing: 0) {
                    // Divider
                    Divider()
                        .background(ANCHORDesign.Colors.primary.opacity(0.1))
                    
                    HStack(spacing: 0) {
                        TabBarButton(
                            icon: "house.fill",
                            label: "Home",
                            isSelected: selectedTab == 0,
                            action: { withAnimation(.spring()) { selectedTab = 0 } }
                        )
                        
                        Spacer(minLength: 0)
                        
                        // Center FAB
                        Button(action: { showingNewEntry = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
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
                                .offset(y: -28)
                        }
                        .buttonStyle(ScaleButtonStyle())
                        .frame(width: 56, height: 56)
                        
                        Spacer(minLength: 0)
                        
                        TabBarButton(
                            icon: "book.fill",
                            label: "Journal",
                            isSelected: selectedTab == 1,
                            action: { withAnimation(.spring()) { selectedTab = 1 } }
                        )
                        
                        Spacer(minLength: 0)
                        
                        TabBarButton(
                            icon: "person.fill",
                            label: "Profile",
                            isSelected: selectedTab == 2,
                            action: { withAnimation(.spring()) { selectedTab = 2 } }
                        )
                    }
                    .padding(.top, 12)
                    .padding(.horizontal)
                    .frame(height: 60)
                    .background(ANCHORDesign.Colors.backgroundCard)
                    .overlay(
                        Rectangle()
                            .frame(width: nil, height: 0.5, alignment: .top)
                            .foregroundColor(ANCHORDesign.Colors.primary.opacity(0.1)),
                        alignment: .top
                    )
                },
                alignment: .bottom
            )
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
        .sheet(isPresented: $showingNewEntry) {
            // New Entry View
            NavigationView {
                JournalEditorView(onSave: { _ in
                    // Handle save action
                    Task {
                        await journalVM.refreshEntries()
                    }
                    showingNewEntry = false
                })
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

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? ANCHORDesign.Colors.primary : ANCHORDesign.Colors.textSecondary)
                
                Text(label)
                    .font(.caption2)
                    .fontWeight(isSelected ? .medium : .regular)
                    .foregroundColor(isSelected ? ANCHORDesign.Colors.primary : ANCHORDesign.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - View Extension to Hide Navigation Bar
extension View {
    func hideNavigationBar() -> some View {
        self
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarHidden(true)
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let authManager = AuthManager.shared
        let previewUser = AuthManager.User(
            id: "1", 
            email: "preview@example.com", 
            name: "Preview User"
        )
        authManager.updateForPreview(isAuthenticated: true, user: previewUser)
        
        return ContentView()
            .environmentObject(authManager)
            .environmentObject(JournalViewModel())
            .environment(\.colorScheme, .light)
    }
}
