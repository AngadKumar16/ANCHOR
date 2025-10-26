//
//  DashboardView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//

import SwiftUI
import UIKit

struct DashboardView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @StateObject private var sobrietyTracker = SobrietyTracker()
    @ObservedObject private var dailyQuoteService = DailyQuoteService.shared
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
            .background(ANCHORDesign.Colors.background)
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingJournalEntry) {
            NavigationView {
                JournalEntryView(entry: nil)
                    .environmentObject(journalVM)
            }
        }
        .sheet(isPresented: $showingBreathingExercise) {
            NavigationView {
                BreathingExerciseView()
            }
        }
        .sheet(isPresented: $showingCheckIn) {
            NavigationView {
                VStack(spacing: 20) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 60))
                        .foregroundColor(ANCHORDesign.Colors.primary)
                    
                    Text("Check-In Feature")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("The check-in feature will be available in the next update. Stay tuned!")
                        .multilineTextAlignment(.center)
                        .foregroundColor(ANCHORDesign.Colors.textSecondary)
                        .padding(.horizontal)
                }
                .padding()
                .navigationTitle("Check-In")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") {
                            showingCheckIn = false
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingRiskAssessment) {
            NavigationView {
                RiskAssessmentView()
                    .environmentObject(RiskAssessmentViewModel(viewContext: PersistenceController.shared.container.viewContext))
            }
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
            daysToNextMilestone: sobrietyTracker.nextMilestone.days - sobrietyTracker.daysSober
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
                    style: .gradient,
                    customGradient: [ANCHORDesign.Colors.primary, ANCHORDesign.Colors.primaryLight],
                    action: {
                        showingJournalEntry = true
                    }
                )
                
                QuickActionCard(
                    title: "Breathing",
                    subtitle: "Calm your mind",
                    icon: "wind",
                    style: .gradient,
                    customGradient: [ANCHORDesign.Colors.accent, ANCHORDesign.Colors.accentLight],
                    action: {
                        showingBreathingExercise = true
                    }
                )
                
                QuickActionCard(
                    title: "Check-In",
                    subtitle: "How are you?",
                    icon: "heart.fill",
                    style: .gradient,
                    customGradient: [ANCHORDesign.Colors.moodHappy, ANCHORDesign.Colors.moodHappy],
                    action: {
                        showingCheckIn = true
                    }
                )
                
                QuickActionCard(
                    title: "Risk Check",
                    subtitle: "Assess your state",
                    icon: "shield.fill",
                    style: .gradient,
                    customGradient: [ANCHORDesign.Colors.warning, ANCHORDesign.Colors.moodNeutral],
                    action: {
                        showingRiskAssessment = true
                    }
                )
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
                
                NavigationLink(destination: JournalListView().environmentObject(journalVM)) {
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
                            ANCHORMoodIcon(mood: moodFromSentiment(recentEntry.sentiment ?? 0.0), size: 24)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(recentEntry.title ?? "Journal Entry")
                                    .anchorTextStyle(.bodyBold)
                                    .lineLimit(1)
                                
                                Text(recentEntry.createdAt, style: .date)
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
                                    ForEach(Array(recentEntry.tags.prefix(3).enumerated()), id: \.offset) { _, tag in
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
                        
                        Button(action: { showingJournalEntry = true }) {
                            Text("Write First Entry")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(ANCHORDesign.Colors.primary)
                                .cornerRadius(8)
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
                
                Text(dailyQuoteService.getTodaysQuote().text)
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
                    title: "Practice Self-Compassion",
                    message: "Be kind to yourself. Recovery is a journey, not a destination.",
                    systemImage: "heart.fill"
                )
                
                RecoveryTipCard(
                    title: "Stay Connected",
                    message: "Reach out to your support network when you need help.",
                    systemImage: "person.2.fill"
                )
                
                RecoveryTipCard(
                    title: "Prioritize Sleep",
                    message: "Good sleep is essential for mental health and recovery.",
                    systemImage: "moon.fill"
                )
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func moodFromSentiment(_ sentiment: Double) -> ANCHORMoodIcon.MoodType {
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
        let quote = dailyQuoteService.getTodaysQuote().text
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
