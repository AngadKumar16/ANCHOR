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
    
    private let recoveryTips = [
        "Practice deep breathing for 5 minutes",
        "Reach out to a friend today",
        "Write down three things you're grateful for",
        "Take a short walk outside",
        "Try a quick meditation session"
    ]
    
    private let recoveryTipIcons = [
        "wind",
        "person.2.fill",
        "heart.fill",
        "figure.walk",
        "leaf.fill"
    ]
    
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
        ANCHORCard.gradient(
            Gradient(colors: [ANCHORDesign.Colors.primary, ANCHORDesign.Colors.secondary]),
            padding: ANCHORDesign.Spacing.lg
        ) {
            HStack {
                VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.sm) {
                    Text("Welcome Back,")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                    
                    Text("Friend")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.trailing, 4)
            }
        }
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
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: ANCHORDesign.Spacing.md),
                GridItem(.flexible(), spacing: ANCHORDesign.Spacing.md)
            ], spacing: ANCHORDesign.Spacing.md) {
                quickActionButton(
                    title: "New Entry",
                    icon: "plus.circle.fill",
                    color: .blue,
                    action: { showingJournalEntry = true }
                )
                
                quickActionButton(
                    title: "Breathe",
                    icon: "wind",
                    color: .green,
                    action: { showingBreathingExercise = true }
                )
                
                quickActionButton(
                    title: "Check-In",
                    icon: "checkmark.circle.fill",
                    color: .orange,
                    action: { showingCheckIn = true }
                )
                
                quickActionButton(
                    title: "Assess Risk",
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    action: { showingRiskAssessment = true }
                )
            }
        }
    }
    
    private func quickActionButton(
        title: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ANCHORCard(
                padding: ANCHORDesign.Spacing.lg,
                cornerRadius: ANCHORDesign.CornerRadius.medium,
                shadowStyle: ANCHORDesign.Shadow.small,
                backgroundColor: color.opacity(0.1),
                showBorder: true
            ) {
                VStack(spacing: ANCHORDesign.Spacing.sm) {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(color)
                    
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ANCHORDesign.Colors.textPrimary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.vertical, ANCHORDesign.Spacing.sm)
            }
            .frame(height: 100)
        }
        .buttonStyle(ScaleButtonStyle())
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
                        .font(.subheadline)
                        .foregroundColor(ANCHORDesign.Colors.primary)
                }
            }
            .padding(.horizontal, ANCHORDesign.Spacing.xs)
            
            if let recentEntry = journalVM.entries.first {
                ANCHORCard.gradient(
                    Gradient(colors: [ANCHORDesign.Colors.secondary.opacity(0.7), ANCHORDesign.Colors.primary.opacity(0.7)]),
                    padding: ANCHORDesign.Spacing.lg
                ) {
                    VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.md) {
                        HStack {
                            Text(recentEntry.title ?? "Untitled Entry")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text(recentEntry.createdAt, style: .date)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Text(recentEntry.body.prefix(120) + (recentEntry.body.count > 120 ? "..." : ""))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                            .lineLimit(3)
                        
                        HStack {
                            Spacer()
                            Text("Tap to view")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.top, ANCHORDesign.Spacing.xs)
                        }
                    }
                }
            } else {
                ANCHORCard(
                    padding: ANCHORDesign.Spacing.lg,
                    backgroundColor: ANCHORDesign.Colors.backgroundCard,
                    showBorder: true
                ) {
                    VStack(spacing: ANCHORDesign.Spacing.md) {
                        Image(systemName: "text.badge.plus")
                            .font(.title2)
                            .foregroundColor(ANCHORDesign.Colors.primary)
                        
                        Text("No entries yet")
                            .font(.subheadline)
                            .foregroundColor(ANCHORDesign.Colors.textSecondary)
                        
                        Button(action: { showingJournalEntry = true }) {
                            Text("Create your first entry")
                                .font(.subheadline)
                                .foregroundColor(ANCHORDesign.Colors.primary)
                                .padding(.vertical, ANCHORDesign.Spacing.xs)
                                .padding(.horizontal, ANCHORDesign.Spacing.md)
                                .background(ANCHORDesign.Colors.primary.opacity(0.1))
                                .cornerRadius(ANCHORDesign.CornerRadius.small)
                        }
                        .padding(.top, ANCHORDesign.Spacing.xs)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ANCHORDesign.Spacing.lg)
                }
            }
        }
    }
    
    // MARK: - Daily Motivation Section
    
    private var dailyMotivationSection: some View {
        ANCHORCard.gradient(
            Gradient(colors: [.purple, .pink]),
            padding: ANCHORDesign.Spacing.lg,
            shadowStyle: ANCHORDesign.Shadow.medium
        ) {
            VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.md) {
                HStack {
                    Image(systemName: "quote.opening")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Daily Motivation")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button(action: {
                        // No action needed as we're using a daily quote
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                
                let quote = DailyQuoteService.shared.getTodaysQuote()
                Text("\\(quote.text)")
                    .font(.body.italic())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.leading)
                
                Text("- \(quote.author)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
    
    // MARK: - Recovery Tips Section
    
    private var recoveryTipsSection: some View {
        VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.md) {
            Text("Recovery Tips")
                .anchorTextStyle(.title2)
                .padding(.horizontal, ANCHORDesign.Spacing.xs)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: ANCHORDesign.Spacing.md) {
                    ForEach(0..<5) { index in
                        ANCHORCard(
                            padding: ANCHORDesign.Spacing.md,
                            backgroundColor: ANCHORDesign.Colors.backgroundCard,
                            showBorder: true
                        ) {
                            VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.sm) {
                                Image(systemName: recoveryTipIcons[index])
                                    .font(.title2)
                                    .foregroundColor(ANCHORDesign.Colors.primary)
                                
                                Text(recoveryTips[index])
                                    .font(.subheadline)
                                    .foregroundColor(ANCHORDesign.Colors.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(width: 150, height: 120, alignment: .topLeading)
                        }
                    }
                }
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
