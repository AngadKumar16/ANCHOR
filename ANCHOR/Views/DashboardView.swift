//
//  DashboardView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @EnvironmentObject var riskVM: RiskAssessmentViewModel
    @StateObject private var sobrietyTracker = SobrietyTracker()
    @StateObject private var quoteService = DailyQuoteService.shared
    @State private var showCheckIn = false
    @State private var showNewJournal = false
    @State private var showRiskAssessment = false
    @State private var showSettings = false
    @State private var showBreathing = false
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default: return "Good night"
        }
    }
    
    private var recentEntries: [JournalEntryModel] {
        Array(journalVM.entries.prefix(3))
    }
    
    private var latestRiskScore: Double? {
        riskVM.fetchRecent(limit: 1).first?.score
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Sobriety Counter - Most Prominent
                    sobrietyCounterSection()
                    
                    // Streak Progress Ring
                    streakProgressSection()
                    
                    // Quick Action Buttons
                    quickActionsSection()
                    
                    // Last Journal Preview
                    lastJournalPreviewSection()
                    
                    // Daily Quote Banner
                    dailyQuoteBanner()
                    
                    // Upcoming Events / Tips
                    upcomingTipsSection()
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "person.circle")
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showCheckIn) {
                NavigationView {
                    CheckInView()
                        .environmentObject(journalVM)
                        .navigationTitle("Daily Check-in")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showNewJournal) {
                NavigationView {
                    JournalEntryView()
                        .environmentObject(journalVM)
                        .navigationTitle("New Entry")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showRiskAssessment) {
                NavigationView {
                    RiskQuestionView()
                        .environmentObject(riskVM)
                        .navigationTitle("Risk Assessment")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showSettings) {
                NavigationView {
                    SettingsView()
                        .navigationTitle("Settings")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showBreathing) {
                NavigationView {
                    BreathingExerciseView()
                        .navigationTitle("Breathing Exercise")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private func sobrietyCounterSection() -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text(sobrietyTracker.formattedSobrietyTime)
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text(sobrietyTracker.sobrietyStartDateFormatted)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.green.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
        }
        .padding(.top, 10)
    }
    
    private func streakProgressSection() -> some View {
        VStack(spacing: 16) {
            Text("Progress to \(sobrietyTracker.nextMilestone.description)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 12)
                    .opacity(0.3)
                    .foregroundColor(.blue)
                
                Circle()
                    .trim(from: 0.0, to: sobrietyTracker.progressToNextMilestone)
                    .stroke(style: StrokeStyle(lineWidth: 12, lineCap: .round, lineJoin: .round))
                    .foregroundColor(.blue)
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.easeInOut(duration: 1.0), value: sobrietyTracker.progressToNextMilestone)
                
                VStack(spacing: 4) {
                    Text("\(sobrietyTracker.nextMilestone.days - sobrietyTracker.daysSober)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    
                    Text("days to go")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 150, height: 150)
        }
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func quickActionsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quick Actions")
                .font(.headline)
            
            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    QuickActionButton(
                        title: "New Journal Entry",
                        icon: "pencil.circle.fill",
                        color: .blue,
                        action: { showNewJournal = true }
                    )
                    
                    QuickActionButton(
                        title: "Start Breathing",
                        icon: "wind.circle.fill",
                        color: .green,
                        action: { showBreathing = true }
                    )
                }
                
                HStack(spacing: 12) {
                    QuickActionButton(
                        title: "Daily Check-in",
                        icon: "heart.circle.fill",
                        color: .pink,
                        action: { showCheckIn = true }
                    )
                    
                    QuickActionButton(
                        title: "Risk Assessment",
                        icon: "shield.checkerboard",
                        color: .orange,
                        action: { showRiskAssessment = true }
                    )
                }
            }
        }
    }
    
    private func lastJournalPreviewSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Last Journal Entry")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink("View All") {
                    JournalListView()
                        .environmentObject(journalVM)
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if let lastEntry = journalVM.entries.first {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(lastEntry.title ?? "Untitled Entry")
                            .font(.headline)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Text(lastEntry.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Text(lastEntry.body)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    
                    Text("No journal entries yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Button("Write your first entry") {
                        showNewJournal = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
        }
    }
    
    private func dailyQuoteBanner() -> some View {
        let todaysQuote = quoteService.getTodaysQuote()
        
        return VStack(alignment: .leading, spacing: 16) {
            Text("Daily Inspiration")
                .font(.headline)
            
            VStack(spacing: 16) {
                Text("\"\(todaysQuote.text)\"")
                    .font(.title3)
                    .fontStyle(.italic)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                
                HStack {
                    Text("— \(todaysQuote.author)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: shareQuote) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    private func upcomingTipsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recovery Tips")
                .font(.headline)
            
            VStack(spacing: 12) {
                if sobrietyTracker.daysSober == 7 {
                    TipCard(
                        icon: "party.popper.fill",
                        title: "One Week Milestone!",
                        description: "Celebrate this achievement with something you enjoy. You've made it through the first week!",
                        color: .green
                    )
                } else if sobrietyTracker.daysSober == 30 {
                    TipCard(
                        icon: "star.fill",
                        title: "One Month Strong!",
                        description: "You've built incredible momentum. Consider sharing your success with someone you trust.",
                        color: .orange
                    )
                } else if sobrietyTracker.daysSober < 7 {
                    TipCard(
                        icon: "heart.fill",
                        title: "Take it One Day at a Time",
                        description: "Focus on today. Each day is a victory and brings you closer to your goals.",
                        color: .pink
                    )
                } else {
                    TipCard(
                        icon: "leaf.fill",
                        title: "Stay Mindful",
                        description: "Practice mindfulness today. Take a few minutes to breathe and center yourself.",
                        color: .green
                    )
                }
                
                TipCard(
                    icon: "person.2.fill",
                    title: "Connect with Support",
                    description: "Reach out to your support network. Connection is a powerful tool in recovery.",
                    color: .blue
                )
            }
        }
    }
    
    private func todaysSnapshotSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today's Snapshot")
                .font(.headline)
            
            VStack(spacing: 16) {
                HStack(spacing: 16) {
                    SnapshotCard(
                        title: "Journal Entries",
                        value: "\(journalVM.entries.filter { Calendar.current.isDateInToday($0.date) }.count)",
                        icon: "book.fill",
                        color: .blue
                    )
                    
                    SnapshotCard(
                        title: "Risk Level",
                        value: latestRiskScore != nil ? "\(Int(latestRiskScore!))%" : "--",
                        icon: "shield.fill",
                        color: riskColor(for: latestRiskScore ?? 0)
                    )
                }
                
                HStack(spacing: 16) {
                    SnapshotCard(
                        title: "Streak",
                        value: "\(calculateStreak()) days",
                        icon: "flame.fill",
                        color: .orange
                    )
                    
                    SnapshotCard(
                        title: "Mood",
                        value: averageMoodEmoji(),
                        icon: "face.smiling.fill",
                        color: .yellow
                    )
                }
            }
        }
    }
    
    private func recentJournalSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Entries")
                    .font(.headline)
                
                Spacer()
                
                NavigationLink("View All") {
                    JournalListView()
                        .environmentObject(journalVM)
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if recentEntries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "book.closed")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    
                    Text("No entries yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Start your wellness journey by writing your first journal entry.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            } else {
                ForEach(recentEntries) { entry in
                    JournalEntryCard(entry: entry)
                }
            }
        }
    }
    
    private func wellnessTipsSection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Wellness Tips")
                .font(.headline)
            
            WellnessTipCard(
                tip: "Take a moment to breathe deeply and center yourself.",
                icon: "wind"
            )
        }
    }
    
    // MARK: - Helper Functions
    
    private func riskColor(for score: Double) -> Color {
        switch score {
        case 0..<30: return .green
        case 30..<70: return .orange
        case 70...100: return .red
        default: return .gray
        }
    }
    
    private func calculateStreak() -> Int {
        // Simple streak calculation based on consecutive days with entries
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        while true {
            let hasEntry = journalVM.entries.contains { calendar.isDate($0.date, inSameDayAs: currentDate) }
            if hasEntry {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else {
                break
            }
        }
        
        return streak
    }
    
    private func averageMoodEmoji() -> String {
        let recentMoods = journalVM.entries.prefix(7).compactMap { $0.sentiment }
        guard !recentMoods.isEmpty else { return "😐" }
        
        let average = Double(recentMoods.reduce(0, +)) / Double(recentMoods.count)
        
        switch average {
        case 0.5...1.0: return "😊"
        case 0.1..<0.5: return "🙂"
        case -0.1...0.1: return "😐"
        case -0.5..<(-0.1): return "😔"
        default: return "😢"
        }
    }
}

    // MARK: - Helper Functions
    
    private func shareQuote() {
        let quote = quoteService.getTodaysQuote()
        let shareText = "\"\(quote.text)\" — \(quote.author)"
        
        let activityVC = UIActivityViewController(activityItems: [shareText], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Supporting Views

private struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
    }
}

private struct TipCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct SnapshotCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Spacer()
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct JournalEntryCard: View {
    let entry: JournalEntryModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(entry.title ?? "Untitled")
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(entry.body)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

private struct WellnessTipCard: View {
    let tip: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
            
            Text(tip)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    DashboardView()
        .environmentObject(JournalViewModel())
        .environmentObject(RiskAssessmentViewModel())
}
