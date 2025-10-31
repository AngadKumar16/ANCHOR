//
//  DashboardView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//

import ANCHOR
import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel(title: "Dashboard")
    @State private var showingJournalEntry = false
    @State private var showingCheckIn = false
    @State private var showingBreathingExercise = false
    @State private var showingRiskAssessment = false
    @State private var checkInStatus: CheckInStatus = .notStarted
    
    @StateObject private var quoteService = DailyQuoteService.shared
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            // Dynamic background gradient based on color scheme
            LinearGradient(
                gradient: Gradient(colors: colorScheme == .dark ? 
                                 [Color(hex: "1A1A2E"), Color(hex: "16213E")] : 
                                 [Color(hex: "E0F7FA"), Color.white]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome back,")
                            .font(.headline)
                            .foregroundColor(ANCHORDesign.Colors.textSecondary)
                        Text("User")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(ANCHORDesign.Colors.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(ANCHORDesign.Colors.backgroundCard)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                    )
                    .padding(.top, 24)
                    
                    // Quick Actions Grid
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Actions")
                            .font(.headline)
                            .foregroundColor(ANCHORDesign.Colors.textPrimary)
                            .padding(.horizontal, 8)
                        
                        // 2x2 Grid for quick actions
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            QuickActionButton(
                                title: "New Entry",
                                icon: "plus.circle.fill",
                                color: ANCHORDesign.Colors.accentPrimary,
                                action: { showingJournalEntry = true }
                            )
                            
                            QuickActionButton(
                                title: "Check In",
                                icon: "checkmark.circle.fill",
                                color: ANCHORDesign.Colors.accentSecondary,
                                action: { showingCheckIn = true }
                            )
                            
                            QuickActionButton(
                                title: "Breathe",
                                icon: "wind",
                                color: ANCHORDesign.Colors.success,
                                action: { showingBreathingExercise = true }
                            )
                            
                            QuickActionButton(
                                title: "Assess Risk",
                                icon: "exclamationmark.triangle.fill",
                                color: ANCHORDesign.Colors.error,
                                action: { showingRiskAssessment = true }
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(ANCHORDesign.Colors.backgroundCard)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                    )
                    
                    // Mood & Progress Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Mood & Progress")
                            .font(.headline)
                            .foregroundColor(ANCHORDesign.Colors.textPrimary)
                            .padding(.horizontal, 8)
                        
                        // Mood chart/overview would go here
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ANCHORDesign.Colors.backgroundSecondary)
                            .frame(height: 180)
                            .overlay(
                                Text("Mood Chart")
                                    .foregroundColor(ANCHORDesign.Colors.textSecondary)
                            )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(ANCHORDesign.Colors.backgroundCard)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                    )
                    
                    // Daily Inspiration
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Inspiration")
                            .font(.headline)
                            .foregroundColor(ANCHORDesign.Colors.textPrimary)
                            .padding(.horizontal, 8)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\"\(quoteService.currentQuote.text)\"")
                                .font(.body)
                                .foregroundColor(ANCHORDesign.Colors.textPrimary)
                                .lineSpacing(4)
                            
                            if !quoteService.currentQuote.author.isEmpty {
                                Text("— \(quoteService.currentQuote.author)")
                                    .font(.subheadline)
                                    .foregroundColor(ANCHORDesign.Colors.textSecondary)
                                    .frame(maxWidth: .infinity, alignment: .trailing)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(ANCHORDesign.Colors.backgroundSecondary)
                        .cornerRadius(12)
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(ANCHORDesign.Colors.backgroundCard)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                    )
                    
                    // Resources Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Resources")
                            .font(.headline)
                            .foregroundColor(ANCHORDesign.Colors.textPrimary)
                            .padding(.horizontal, 8)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ResourceCard(
                                title: "Guided Meditations",
                                icon: "headphones",
                                color: ANCHORDesign.Colors.accentPrimary
                            )
                            
                            ResourceCard(
                                title: "Sleep Sounds",
                                icon: "moon.zzz.fill",
                                color: ANCHORDesign.Colors.accentSecondary
                            )
                            
                            ResourceCard(
                                title: "Emergency Contacts",
                                icon: "phone.fill",
                                color: ANCHORDesign.Colors.error
                            )
                            
                            ResourceCard(
                                title: "Therapist Finder",
                                icon: "person.2.fill",
                                color: ANCHORDesign.Colors.success
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(ANCHORDesign.Colors.backgroundCard)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
                    )
                    
                    Spacer(minLength: 32)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingJournalEntry) {
            NavigationView {
                JournalEntryView(entry: nil)
                    .environmentObject(JournalViewModel(context: PersistenceController.shared.container.viewContext))
                    .navigationBarItems(trailing: Button("Done") {
                        showingJournalEntry = false
                    })
            }
        }
        .sheet(isPresented: $showingCheckIn) {
            NavigationView {
                CheckInView(checkInStatus: .constant(.inProgress))
                    .navigationBarItems(trailing: Button("Done") {
                        showingCheckIn = false
                    })
            }
        }
        .sheet(isPresented: $showingBreathingExercise) {
            NavigationView {
                BreathingExerciseView()
                    .navigationBarItems(trailing: Button("Done") {
                        showingBreathingExercise = false
                    })
            }
        }
        .sheet(isPresented: $showingRiskAssessment) {
            NavigationView {
                RiskAssessmentView()
                    .environmentObject(RiskAssessmentViewModel(viewContext: PersistenceController.shared.container.viewContext))
                    .navigationBarItems(trailing: Button("Done") {
                        showingRiskAssessment = false
                    })
            }
        }
    }
}

// MARK: - Quick Action Button
private struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(color.opacity(0.2))
                    .foregroundColor(color)
                    .clipShape(Circle())
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(ANCHORDesign.Colors.textPrimary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .padding(12)
            .background(ANCHORDesign.Colors.backgroundSecondary)
            .cornerRadius(12)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Resource Card
private struct ResourceCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .padding(12)
                .background(color.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(ANCHORDesign.Colors.textPrimary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(ANCHORDesign.Colors.backgroundSecondary)
        .cornerRadius(12)
    }
}

// MARK: - Preview
struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DashboardView()
                .preferredColorScheme(.dark)
        }
    }
}
