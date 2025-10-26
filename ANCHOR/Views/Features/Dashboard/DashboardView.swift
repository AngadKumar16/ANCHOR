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
    
    // Add this new state for check-in
    @State private var checkInStatus: CheckInStatus = .notStarted
    
    private enum CheckInStatus {
        case notStarted, inProgress, completed
    }
    
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
    
    private let recoveryTipColors: [Color] = [.blue, .green, .orange, .purple, .teal]
    
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
            CheckInView()
                .onDisappear {
                    // Handle any cleanup when the check-in is dismissed
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
        VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(.title3)
                        .foregroundColor(ANCHORDesign.Colors.textSecondary)
                    
                    Text("Friend")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(LinearGradient(
                            colors: [ANCHORDesign.Colors.primary, ANCHORDesign.Colors.accent],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                }
                
                Spacer()
                
                // Profile/Notification Icons
                HStack(spacing: 16) {
                    Button(action: {}) {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "bell.fill")
                                .font(.title3)
                                .foregroundColor(ANCHORDesign.Colors.primary)
                            
                            Circle()
                                .fill(ANCHORDesign.Colors.accent)
                                .frame(width: 10, height: 10)
                                .offset(x: 2, y: -2)
                        }
                    }
                    
                    Button(action: {}) {
                        Image(systemName: "person.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [ANCHORDesign.Colors.primary, ANCHORDesign.Colors.accent],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            
            // Date and Stats
            HStack {
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundColor(ANCHORDesign.Colors.textSecondary)
                
                Spacer()
                
                HStack(spacing: 16) {
                    StatPill(icon: "flame.fill", value: "7", color: .orange)
                    StatPill(icon: "checkmark.seal.fill", value: "24", color: .green)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(ANCHORDesign.Colors.backgroundCard)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
    
    // MARK: - Stat Pill
    struct StatPill: View {
        let icon: String
        let value: String
        let color: Color
        
        var body: some View {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(ANCHORDesign.Colors.textPrimary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(12)
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
                .padding(.leading, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: ANCHORDesign.Spacing.md),
                GridItem(.flexible(), spacing: ANCHORDesign.Spacing.md)
            ], spacing: ANCHORDesign.Spacing.md) {
                QuickActionButton(
                    title: "New Entry",
                    icon: "plus.circle.fill",
                    color: ANCHORDesign.Colors.primary,
                    action: { showingJournalEntry = true }
                )
                
                QuickActionButton(
                    title: "Breathe",
                    icon: "wind",
                    color: .teal,
                    action: { showingBreathingExercise = true }
                )
                
                QuickActionButton(
                    title: "Check-In",
                    icon: "checkmark.circle.fill",
                    color: checkInStatus == .completed ? .green : .orange,
                    action: { showCheckIn() }
                )
                
                QuickActionButton(
                    title: "Risk Assessment",
                    icon: "exclamationmark.shield.fill",
                    color: .red,
                    action: { showingRiskAssessment = true }
                )
            }
        }
    }
    
    private func showCheckIn() {
        // Reset check-in status when showing the check-in
        checkInStatus = .inProgress
        showingCheckIn = true
    }
    
    // MARK: - Quick Action Button
    struct QuickActionButton: View {
        let title: String
        let icon: String
        let color: Color
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.1))
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(color)
                    }
                    
                    Text(title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(ANCHORDesign.Colors.textPrimary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(ANCHORDesign.Colors.backgroundCard)
                .cornerRadius(16)
                .shadow(color: color.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .buttonStyle(ScaleButtonStyle())
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
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(ANCHORDesign.Colors.primary)
                }
            }
            .padding(.horizontal, ANCHORDesign.Spacing.xs)
            
            if let recentEntry = journalVM.entries.first {
                ANCHORCard.gradient(
                    Gradient(colors: [
                        ANCHORDesign.Colors.primary.opacity(0.9),
                        ANCHORDesign.Colors.secondary.opacity(0.8)
                    ]),
                    padding: ANCHORDesign.Spacing.lg
                ) {
                    VStack(alignment: .leading, spacing: ANCHORDesign.Spacing.md) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recentEntry.title ?? "Untitled Entry")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text(recentEntry.createdAt, style: .date)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            // Mood indicator based on sentiment
                            if let sentiment = recentEntry.sentiment {
                                Circle()
                                    .fill(moodColor(for: sentiment))
                                    .frame(width: 12, height: 12)
                                    .shadow(color: .black.opacity(0.2), radius: 2, x: 0, y: 1)
                            }
                        }
                        
                        Text(recentEntry.body.prefix(120) + (recentEntry.body.count > 120 ? "..." : ""))
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.95))
                            .lineLimit(3)
                        
                        if !recentEntry.tags.isEmpty {
                            HStack {
                                ForEach(Array(recentEntry.tags.prefix(3).enumerated()), id: \.offset) { _, tag in
                                    Text(tag)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.white.opacity(0.2))
                                        .foregroundColor(.white)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        
                        HStack {
                            Spacer()
                            Text("Tap to view")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .padding(.top, 4)
                        }
                    }
                    .onTapGesture {
                        // Handle tap to view full entry
                    }
                }
            } else {
                // No entries state
                ANCHORCard(padding: ANCHORDesign.Spacing.lg) {
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
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(ANCHORDesign.Colors.primary)
                                .cornerRadius(ANCHORDesign.CornerRadius.medium)
                        }
                        .padding(.top, ANCHORDesign.Spacing.xs)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, ANCHORDesign.Spacing.lg)
                }
            }
        }
    }
    
    private func moodColor(for sentiment: Double) -> Color {
        switch sentiment {
        case ..<(-0.3):
            return .red // Negative mood
        case -0.3..<0.3:
            return .yellow // Neutral mood
        default:
            return .green // Positive mood
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
                Text("\"\(quote.text)\"")
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
                    ForEach(Array(zip(recoveryTips.indices, recoveryTips)), id: \.0) { index, tip in
                        recoveryTipCard(
                            tip: tip,
                            icon: recoveryTipIcons[index % recoveryTipIcons.count],
                            color: recoveryTipColors[index % recoveryTipColors.count]
                        )
                    }
                }
                .padding(.horizontal, ANCHORDesign.Spacing.md)
                .padding(.vertical, 4)
            }
            .padding(.horizontal, -ANCHORDesign.Spacing.md)
        }
    }
    
    private func recoveryTipCard(tip: String, icon: String, color: Color) -> some View {
        HStack(spacing: ANCHORDesign.Spacing.md) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 40)
            
            Text(tip)
                .font(.subheadline)
                .foregroundColor(ANCHORDesign.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            Spacer(minLength: 0)
        }
        .padding(ANCHORDesign.Spacing.md)
        .frame(width: 280, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: ANCHORDesign.CornerRadius.medium)
                .fill(ANCHORDesign.Colors.backgroundCard)
                .shadow(color: color.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: ANCHORDesign.CornerRadius.medium)
                .stroke(color.opacity(0.1), lineWidth: 1)
        )
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
    
    // MARK: - Check-In View
    private struct CheckInView: View {
        @Environment(\.dismiss) private var dismiss
        @State private var mood: Int = 3 // 1-5 scale
        @State private var note: String = ""
        @State private var selectedTags: Set<String> = []
        
        let moodOptions = ["😔", "🙁", "😐", "🙂", "😊"]
        let tagOptions = ["Anxious", "Stressed", "Happy", "Grateful", "Tired", "Energetic", "Focused"]
        
        var body: some View {
            NavigationView {
                Form {
                    // Mood Section
                    Section(header: Text("How are you feeling?")) {
                        HStack(spacing: 0) {
                            ForEach(1...5, id: \.self) { index in
                                Button(action: {
                                    withAnimation {
                                        mood = index
                                    }
                                }) {
                                    Text(moodOptions[index-1])
                                        .font(.system(size: 40))
                                        .opacity(mood >= index ? 1.0 : 0.3)
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Tags Section
                    Section(header: Text("How would you describe your current state?")) {
                        FlowLayout(alignment: .leading, spacing: 8) {
                            ForEach(tagOptions, id: \.self) { tag in
                                Button(action: {
                                    if selectedTags.contains(tag) {
                                        selectedTags.remove(tag)
                                    } else {
                                        selectedTags.insert(tag)
                                    }
                                }) {
                                    HStack {
                                        Text(tag)
                                        if selectedTags.contains(tag) {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(selectedTags.contains(tag) ? ANCHORDesign.Colors.primary.opacity(0.2) : ANCHORDesign.Colors.backgroundSecondary)
                                    .foregroundColor(selectedTags.contains(tag) ? ANCHORDesign.Colors.primary : ANCHORDesign.Colors.textPrimary)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(selectedTags.contains(tag) ? ANCHORDesign.Colors.primary : ANCHORDesign.Colors.backgroundSecondary, lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Notes Section
                    Section(header: Text("Add a note (optional)")) {
                        TextEditor(text: $note)
                            .frame(minHeight: 100)
                            .background(ANCHORDesign.Colors.backgroundSecondary)
                            .cornerRadius(8)
                    }
                }
                .navigationTitle("Daily Check-In")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            // Save check-in data
                            // You can add your save logic here
                            
                            // For now, just dismiss and show completion
                            dismiss()
                            
                            // In a real app, you would save this data to CoreData
                            // and then update the UI accordingly
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                // Show completion state
                                checkInStatus = .completed
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Flow Layout for Tags
    private struct FlowLayout: Layout {
        let alignment: Alignment
        let spacing: CGFloat
        
        init(alignment: Alignment = .center, spacing: CGFloat = 8) {
            self.alignment = alignment
            self.spacing = spacing
        }
        
        func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
            let maxWidth = proposal.width ?? 0
            var height: CGFloat = 0
            var rowWidth: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if rowWidth + size.width + spacing > maxWidth && rowWidth > 0 {
                    height += rowHeight + spacing
                    rowWidth = 0
                    rowHeight = 0
                }
                
                if rowWidth > 0 {
                    rowWidth += spacing
                }
                
                rowWidth += size.width
                rowHeight = max(rowHeight, size.height)
            }
            
            height += rowHeight
            
            return CGSize(width: maxWidth, height: height)
        }
        
        func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
            let maxWidth = bounds.width
            var point = bounds.origin
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if point.x + size.width > maxWidth && point.x > bounds.minX {
                    point.x = bounds.minX
                    point.y += rowHeight + spacing
                    rowHeight = 0
                }
                
                subview.place(
                    at: point,
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                
                point.x += size.width + spacing
                rowHeight = max(rowHeight, size.height)
            }
        }
    }
}

// MARK: - Supporting Views

#Preview {
    DashboardView()
        .environmentObject(JournalViewModel())
}
