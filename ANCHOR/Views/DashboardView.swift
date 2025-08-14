//
//  DashboardView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//

import SwiftUI
import ANCHORDesign

struct DashboardView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @StateObject private var sobrietyTracker = SobrietyTracker()
    @State private var showingJournalEntry = false
    @State private var showingBreathingExercise = false
    @State private var showingCheckIn = false
    @State private var showingRiskAssessment = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: ANCHORDesign.Spacing.lg) {
                    // Welcome Header
                    welcomeHeader
                    
                    // Sobriety Progress Section
                    sobrietyProgressSection
                    
                    // Quick Actions Grid
                    quickActionsSection
                    
                    // Recent Journal Preview
                    recentJournalSection
                    
                    // Daily Motivation
                    dailyMotivationSection
                    
                    // Recovery Tips
                    recoveryTipsSection
                }
                .padding(.horizontal, ANCHORDesign.Spacing.md)
                .padding(.bottom, ANCHORDesign.Spacing.xxl)
            }
            .anchorGradientBackground()
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingJournalEntry) {
            JournalEntryView()
        }
        .sheet(isPresented: $showingBreathingExercise) {
            BreathingExerciseView()
        }
        .sheet(isPresented: $showingCheckIn) {
            // TODO: Implement CheckInView
            Text("Check-in coming soon!")
        }
        .sheet(isPresented: $showingRiskAssessment) {
            RiskAssessmentView()
        }
    }
    
    // MARK: - Welcome Header
    
    private var welcomeHeader: some View {
        ANCHORCard(padding: ANCHORDesign.Spacing.lg) {
            HStack {
                VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.sm) {
                    Text("Welcome back!")
                        .anchorTextStyle(.title1)
                    
                    Text("How are you feeling today?")
                        .anchorTextStyle(.callout)
                }
                
                Spacer()
                
                // Profile/Settings Button
                Button(action: {
                    // TODO: Navigate to settings
                }) {
                    ZStack {
                        Circle()
                            .fill(ANCHORDesign.Colors.primary.opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundColor(ANCHORDesign.Colors.primary)
                    }
                }
            }
        }
        .padding(.top, ANCHORDesign.Spacing.md)
    }
    
    // MARK: - Sobriety Progress Section
    
    private var sobrietyProgressSection: some View {
        SobrietyProgressCard(
            daysSober: sobrietyTracker.daysSober,
            progressToNextMilestone: sobrietyTracker.progressToNextMilestone,
            nextMilestone: sobrietyTracker.nextMilestone.description,
            daysToNextMilestone: sobrietyTracker.daysToNextMilestone
        )
    }
    
    // MARK: - Quick Actions Section
    
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.md) {
            Text("Quick Actions")
                .anchorTextStyle(.title2)
                .padding(.horizontal, ANCHORDesign.Spacing.xs)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: ANCHORDesign.Spacing.md), count: 2), spacing: ANCHORDesign.Spacing.md) {
                
                QuickActionCard(
                    title: "New Journal",
                    subtitle: "Write your thoughts",
                    icon: "book.fill",
                    gradient: [ANCHORDesign.Colors.primary, ANCHORDesign.Colors.primaryLight]
                ) {
                    showingJournalEntry = true
                }
                
                QuickActionCard(
                    title: "Breathing",
                    subtitle: "Calm your mind",
                    icon: "wind",
                    gradient: [ANCHORDesign.Colors.accent, ANCHORDesign.Colors.accentLight]
                ) {
                    showingBreathingExercise = true
                }
                
                QuickActionCard(
                    title: "Check-In",
                    subtitle: "How are you?",
                    icon: "heart.fill",
                    gradient: [ANCHORDesign.Colors.moodHappy, ANCHORDesign.Colors.moodVeryHappy]
                ) {
                    showingCheckIn = true
                }
                
                QuickActionCard(
                    title: "Risk Check",
                    subtitle: "Assess your state",
                    icon: "shield.fill",
                    gradient: [ANCHORDesign.Colors.warning, ANCHORDesign.Colors.moodNeutral]
                ) {
                    showingRiskAssessment = true
                }
            }
        }
    }
    
    // MARK: - Recent Journal Section
    
    private var recentJournalSection: some View {
        VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.md) {
            HStack {
                Text("Recent Reflections")
                    .anchorTextStyle(.title2)
                
                Spacer()
                
                NavigationLink(destination: JournalListView()) {
                    Text("View All")
                        .anchorTextStyle(.callout)
                        .foregroundColor(ANCHORDesign.Colors.primary)
                }
            }
            .padding(.horizontal, ANCHORDesign.Spacing.xs)
            
            if let recentEntry = journalVM.entries.first {
                ANCHORCard {
                    VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.sm) {
                        HStack {
                            ANCHORMoodIcon(mood: moodFromSentiment(recentEntry.sentiment), size: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(recentEntry.title ?? "Journal Entry")
                                    .anchorTextStyle(.bodyBold)
                                    .lineLimit(1)
                                
                                Text(recentEntry.date, style: .date)
                                    .anchorTextStyle(.caption1)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(ANCHORDesign.Colors.textTertiary)
                        }
                        
                        Text(recentEntry.body)
                            .anchorTextStyle(.callout)
                            .lineLimit(3)
                            .multilineTextAlignment(.leading)
                        
                        if !recentEntry.tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: ANCHORDesign.Spacing.xs) {
                                    ForEach(recentEntry.tags.prefix(3), id: \.self) { tag in
                                        Text(tag)
                                            .font(.system(size: 11, weight: .medium))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(ANCHORDesign.Colors.primary.opacity(0.1))
                                            .foregroundColor(ANCHORDesign.Colors.primary)
                                            .cornerRadius(ANCHORDesign.CornerRadius.small)
                                    }
                                }
                                .padding(.horizontal, 1)
                            }
                        }
                    }
                }
            } else {
                ANCHORCard {
                    VStack(spacing: ANCHORDesign.Spacing.md) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 40))
                            .foregroundColor(ANCHORDesign.Colors.textTertiary)
                        
                        VStack(spacing: ANCHORDesign.Spacing.xs) {
                            Text("Start Your Journey")
                                .anchorTextStyle(.bodyBold)
                            
                            Text("Write your first journal entry to begin tracking your thoughts and progress.")
                                .anchorTextStyle(.callout)
                                .multilineTextAlignment(.center)
                        }
                        
                        ANCHORButton(title: "Write First Entry", style: .primary, size: .medium) {
                            showingJournalEntry = true
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    // MARK: - Daily Motivation Section
    
    private var dailyMotivationSection: some View {
        ANCHORCard(
            padding: ANCHORDesign.Spacing.lg,
            shadowStyle: ANCHORDesign.Shadow.large
        ) {
            VStack(spacing: ANCHORDesign.Spacing.md) {
                HStack {
                    Image(systemName: "quote.bubble.fill")
                        .font(.title2)
                        .foregroundColor(ANCHORDesign.Colors.accent)
                    
                    Text("Daily Inspiration")
                        .anchorTextStyle(.title3)
                    
                    Spacer()
                    
                    Button(action: shareQuote) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title3)
                            .foregroundColor(ANCHORDesign.Colors.primary)
                    }
                }
                
                Text(DailyQuoteService.shared.getTodaysQuote())
                    .anchorTextStyle(.body)
                    .multilineTextAlignment(.center)
                    .italic()
                    .padding(.vertical, ANCHORDesign.Spacing.sm)
            }
        }
    }
    
    // MARK: - Recovery Tips Section
    
    private var recoveryTipsSection: some View {
        VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.md) {
            Text("Recovery Tips")
                .anchorTextStyle(.title2)
                .padding(.horizontal, ANCHORDesign.Spacing.xs)
            
            VStack(spacing: ANCHORDesign.Spacing.sm) {
                RecoveryTipCard(
                    icon: "heart.fill",
                    title: "Practice Self-Compassion",
                    description: "Be kind to yourself. Recovery is a journey, not a destination.",
                    color: ANCHORDesign.Colors.moodHappy
                )
                
                RecoveryTipCard(
                    icon: "person.2.fill",
                    title: "Stay Connected",
                    description: "Reach out to your support network when you need help.",
                    color: ANCHORDesign.Colors.accent
                )
                
                RecoveryTipCard(
                    icon: "moon.fill",
                    title: "Prioritize Sleep",
                    description: "Good sleep is essential for mental health and recovery.",
                    color: ANCHORDesign.Colors.primary
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func moodFromSentiment(_ sentiment: Int) -> ANCHORMoodIcon.MoodType {
        switch sentiment {
        case 2: return .veryHappy
        case 1: return .happy
        case 0: return .neutral
        case -1: return .sad
        case -2: return .verySad
        default: return .neutral
        }
    }
    
    private func shareQuote() {
        let quote = DailyQuoteService.shared.getTodaysQuote()
        let content = "\(quote)\n\n- Shared from ANCHOR"
        
        let activityVC = UIActivityViewController(activityItems: [content], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Supporting Views

#Preview {
    DashboardView()
        .environmentObject(JournalViewModel())
}
