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
    
    var body: some View {
        ScrollView {
            VStack(spacing: ANCHORDesign.Spacing.xxl) {
                // Header
                headerSection
                
                // Quick Actions
                quickActionsSection
                
                // Mood & Progress
                moodProgressSection
                
                // Daily Inspiration
                dailyInspirationSection
                
                // Resources
                resourcesSection
                
                Spacer()
            }
            .padding()
        }
        .background(ANCHORDesign.Colors.backgroundPrimary.ignoresSafeArea())
        .sheet(isPresented: $showingJournalEntry) {
            NavigationView {
                // JournalEntryView()
            }
        }
        .sheet(isPresented: $showingCheckIn) {
            NavigationView {
                CheckInView(checkInStatus: $checkInStatus)
            }
        }
        .sheet(isPresented: $showingBreathingExercise) {
            NavigationView {
                // BreathingExerciseView()
            }
        }
        .sheet(isPresented: $showingRiskAssessment) {
            NavigationView {
                // RiskAssessmentView()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Welcome back,")
                    .font(.title3)
                    .foregroundColor(ANCHORDesign.Colors.textSecondary)
                Text("User")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(ANCHORDesign.Colors.textPrimary)
            }
            
            Spacer()
            
            Button(action: {
                // Show profile/settings
            }) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .foregroundColor(ANCHORDesign.Colors.primary)
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.md) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.leading, 4)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ANCHORDesign.Spacing.md) {
                    QuickActionButton(
                        title: "New Entry",
                        icon: "plus.circle.fill",
                        color: ANCHORDesign.Colors.primary,
                        action: { showingJournalEntry = true }
                    )
                    
                    QuickActionButton(
                        title: "Check In",
                        icon: "checkmark.circle.fill",
                        color: checkInStatus == .completed ? ANCHORDesign.Colors.success : ANCHORDesign.Colors.accent,
                        action: { showingCheckIn = true }
                    )
                    
                    QuickActionButton(
                        title: "Breathe",
                        icon: "wind",
                        color: ANCHORDesign.Colors.info,
                        action: { showingBreathingExercise = true }
                    )
                    
                    QuickActionButton(
                        title: "Risk Check",
                        icon: "exclamationmark.shield.fill",
                        color: ANCHORDesign.Colors.error,
                        action: { showingRiskAssessment = true }
                    )
                }
                .padding(.horizontal, ANCHORDesign.Spacing.md)
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
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.title2)
                    Text(title)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                .frame(width: 80, height: 80)
                .background(color.opacity(0.2))
                .foregroundColor(color)
                .cornerRadius(12)
            }
        }
    }
    
    // MARK: - Mood & Progress Section
    private var moodProgressSection: some View {
        VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.md) {
            Text("Mood & Progress")
                .font(.headline)
                .padding(.leading, 4)
            
            // Mood trend chart placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(ANCHORDesign.Colors.backgroundSecondary)
                .frame(height: 200)
                .overlay(
                    VStack {
                        Text("Mood Trend")
                            .font(.headline)
                        Text("Chart will be displayed here")
                            .font(.subheadline)
                            .foregroundColor(ANCHORDesign.Colors.textSecondary)
                    }
                )
        }
    }
    
    // MARK: - Daily Inspiration Section
    private var dailyInspirationSection: some View {
        VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.md) {
            HStack {
                Text("Daily Inspiration")
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    quoteService.refreshQuote()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(ANCHORDesign.Colors.primary)
                }
            }
            .padding(.leading, 4)
            
            VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.sm) {
                Text("\"\(quoteService.currentQuote.text)\"")
                    .font(.body)
                    .italic()
                    .foregroundColor(ANCHORDesign.Colors.textPrimary)
                
                Text("- \(quoteService.currentQuote.author)")
                    .font(.caption)
                    .foregroundColor(ANCHORDesign.Colors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding()
            .background(ANCHORDesign.Colors.backgroundSecondary)
            .cornerRadius(12)
        }
    }
    
    // MARK: - Resources Section
    private var resourcesSection: some View {
        VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.md) {
            Text("Resources")
                .font(.headline)
                .padding(.leading, 4)
            
            VStack(spacing: ANCHORDesign.Spacing.sm) {
                ResourceCard(
                    title: "Guided Meditation",
                    description: "5 min breathing exercise",
                    icon: "waveform.path.ecg",
                    color: ANCHORDesign.Colors.info,
                    action: { showingBreathingExercise = true }
                )
                
                ResourceCard(
                    title: "Emergency Contacts",
                    description: "Get help when you need it",
                    icon: "phone.fill",
                    color: ANCHORDesign.Colors.error,
                    action: {}
                )
                
                ResourceCard(
                    title: "Community Support",
                    description: "Connect with others",
                    icon: "person.2.fill",
                    color: ANCHORDesign.Colors.primary,
                    action: {}
                )
            }
        }
    }
}

// MARK: - Resource Card
private struct ResourceCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.2))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ANCHORDesign.Colors.textPrimary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(ANCHORDesign.Colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(ANCHORDesign.Colors.textSecondary)
            }
            .padding()
            .background(ANCHORDesign.Colors.backgroundSecondary)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
