import SwiftUI
//import ANCHORDesign

struct JournalListView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @State private var showingNewEntry = false
    @State private var searchText = ""
    @State private var selectedMoodFilter: MoodFilter = .all
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: JournalEntry?
    
    enum MoodFilter: String, CaseIterable {
        case all = "All"
        case positive = "Positive"
        case neutral = "Neutral"
        case negative = "Negative"
        
        var icon: String {
            switch self {
            case .all: return "list.bullet"
            case .positive: return "face.smiling"
            case .neutral: return "face.dashed"
            case .negative: return "face.dashed.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .all: return ANCHORDesign.Colors.primary
            case .positive: return ANCHORDesign.Colors.moodHappy
            case .neutral: return ANCHORDesign.Colors.moodNeutral
            case .negative: return ANCHORDesign.Colors.moodSad
            }
        }
    }
    
    var filteredEntries: [JournalEntry] {
        var entries = journalVM.entries
        
        // Apply search text filter
        if !searchText.isEmpty {
            entries = entries.filter { 
                ($0.title?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                $0.body.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchText) })
            }
        }
        
        // Apply mood filter
        if selectedMoodFilter != .all {
            entries = entries.filter { entry in
                let sentiment = entry.sentiment ?? 0
                switch selectedMoodFilter {
                case .positive: return sentiment > 0
                case .neutral: return sentiment == 0
                case .negative: return sentiment < 0
                case .all: return true
                }
            }
        }
        
        return entries
    }
    
    var groupedEntries: [(String, [JournalEntry])] {
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: entry.createdAt)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                ANCHORGradientBackground()
                
                VStack(spacing: 0) {
                    // Header with Search and Filters
                    headerSection
                    
                    // Journal Entries List
                    if filteredEntries.isEmpty {
                        emptyStateView
                    } else {
                        journalEntriesList
                    }
                }
            }
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: ANCHORDesign.Spacing.md) {
                        // Privacy indicator
                        privacyIndicator
                        
                        // Add button
                        addButton
                    }
                }
            }
            .sheet(isPresented: $showingNewEntry) {
                JournalEntryView()
            }
            .alert("Delete Entry", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let entry = entryToDelete {
                        deleteEntry(entry)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this journal entry? This action cannot be undone.")
            }
        }
        .searchable(text: $searchText, prompt: "Search journal entries")
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: ANCHORDesign.Spacing.md) {
            // Search Bar
            searchBar
            
            // Mood Filter Pills
            moodFilterPills
            
            // Stats Summary
            if !journalVM.entries.isEmpty {
                statsSection
            }
        }
        .padding(.horizontal, ANCHORDesign.Spacing.md)
        .padding(.top, ANCHORDesign.Spacing.sm)
        .padding(.bottom, ANCHORDesign.Spacing.md)
        .background(
            ANCHORDesign.Colors.backgroundCard
                .shadow(
                    color: ANCHORDesign.Shadow.small.color,
                    radius: ANCHORDesign.Shadow.small.radius,
                    x: ANCHORDesign.Shadow.small.x,
                    y: ANCHORDesign.Shadow.small.y
                )
        )
    }
    
    private var searchBar: some View {
        HStack(spacing: ANCHORDesign.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ANCHORDesign.Colors.textSecondary)
                .font(.title3)
            
            TextField("Search entries...", text: $searchText)
                .textFieldStyle(.plain)
                .anchorTextStyle(.body)
            
            if !searchText.isEmpty {
                Button("Clear") {
                    searchText = ""
                }
                .anchorTextStyle(.caption1)
                .foregroundColor(ANCHORDesign.Colors.primary)
            }
        }
        .padding(.horizontal, ANCHORDesign.Spacing.md)
        .padding(.vertical, ANCHORDesign.Spacing.sm)
        .background(ANCHORDesign.Colors.backgroundSecondary)
        .cornerRadius(ANCHORDesign.CornerRadius.medium)
    }
    
    private var moodFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ANCHORDesign.Spacing.sm) {
                ForEach(MoodFilter.allCases, id: \.self) { filter in
                    MoodFilterPill(
                        title: filter.rawValue,
                        icon: filter.icon,
                        color: filter.color,
                        isSelected: selectedMoodFilter == filter
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedMoodFilter = filter
                        }
                    }
                }
            }
            .padding(.horizontal, ANCHORDesign.Spacing.md)
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: ANCHORDesign.Spacing.lg) {
            StatCard(
                title: "Total Entries",
                value: "\(journalVM.entries.count)",
                icon: "book.fill",
                color: ANCHORDesign.Colors.primary
            )
            
            StatCard(
                title: "This Month",
                value: "\(entriesThisMonth)",
                icon: "calendar",
                color: ANCHORDesign.Colors.accent
            )
            
            StatCard(
                title: "Writing Streak",
                value: "\(writingStreak) days",
                icon: "flame.fill",
                color: ANCHORDesign.Colors.warning
            )
        }
    }
    
    // MARK: - Privacy Indicator
    
    private var privacyIndicator: some View {
        HStack(spacing: ANCHORDesign.Spacing.xs) {
            Image(systemName: "lock.fill")
                .font(.caption)
                .foregroundColor(ANCHORDesign.Colors.success)
            
            Text("Private")
                .anchorTextStyle(.caption2)
                .foregroundColor(ANCHORDesign.Colors.success)
        }
        .padding(.horizontal, ANCHORDesign.Spacing.sm)
        .padding(.vertical, ANCHORDesign.Spacing.xs)
        .background(ANCHORDesign.Colors.success.opacity(0.1))
        .cornerRadius(ANCHORDesign.CornerRadius.small)
    }
    
    // MARK: - Add Button
    
    private var addButton: some View {
        Button(action: {
            showingNewEntry = true
        }) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [ANCHORDesign.Colors.primary, ANCHORDesign.Colors.primaryLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(
                        color: ANCHORDesign.Shadow.medium.color,
                        radius: ANCHORDesign.Shadow.medium.radius,
                        x: ANCHORDesign.Shadow.medium.x,
                        y: ANCHORDesign.Shadow.medium.y
                    )
                
                Image(systemName: "plus")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        .scaleEffect(1.0)
        .animation(.easeInOut(duration: 0.1), value: false)
    }
    
    // MARK: - Journal Entries List
    
    private var journalEntriesList: some View {
        ScrollView {
            LazyVStack(spacing: ANCHORDesign.Spacing.md) {
                ForEach(groupedEntries, id: \.0) { monthYear, entries in
                    VStack(spacing: ANCHORDesign.Spacing.sm) {
                        // Month Header
                        MonthHeaderCard(monthYear: monthYear, entryCount: entries.count)
                        
                        // Entries for this month
                        ForEach(entries) { entry in
                            NavigationLink(destination: JournalEntryView(entry: entry)) {
                                JournalEntryCard(entry: entry)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contextMenu {
                                contextMenuForEntry(entry)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, ANCHORDesign.Spacing.md)
            .padding(.bottom, ANCHORDesign.Spacing.xxl)
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: ANCHORDesign.Spacing.lg) {
            Spacer()
            
            // Illustration
            ZStack {
                Circle()
                    .fill(ANCHORDesign.Colors.primary.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: journalVM.entries.isEmpty ? "book.closed" : "magnifyingglass")
                    .font(.system(size: 50))
                    .foregroundColor(ANCHORDesign.Colors.primary)
            }
            
            VStack(spacing: ANCHORDesign.Spacing.sm) {
                Text(journalVM.entries.isEmpty ? "Start Your Journey" : "No Results Found")
                    .anchorTextStyle(.title1)
                
                Text(journalVM.entries.isEmpty 
                     ? "Write your first journal entry to begin tracking your thoughts and progress."
                     : "Try adjusting your search or filter criteria to find what you're looking for.")
                    .anchorTextStyle(.callout)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ANCHORDesign.Spacing.lg)
            }
            
            if journalVM.entries.isEmpty {
                ANCHORButton(title: "Write First Entry", style: .primary, size: .large) {
                    showingNewEntry = true
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Context Menu
    
    private func contextMenuForEntry(_ entry: JournalEntry) -> some View {
        Group {
            Button(action: {
                shareEntry(entry)
            }) {
                Label("Share", systemImage: "square.and.arrow.up")
            }
            
            Button(role: .destructive, action: {
                entryToDelete = entry
                showingDeleteAlert = true
            }) {
                Label("Delete", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private var entriesThisMonth: Int {
        let calendar = Calendar.current
        return journalVM.entries.filter { 
            calendar.isDate($0.createdAt, equalTo: Date(), toGranularity: .month) 
        }.count
    }
    
    private var writingStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = Date()
        
        // Get all unique dates when entries were created
        let entryDates = Set(journalVM.entries.map { 
            calendar.startOfDay(for: $0.createdAt) 
        }).sorted(by: >)
        
        // If no entries, return 0
        guard let mostRecentEntry = entryDates.first else { return 0 }
        
        // If most recent entry is not today, no streak
        if !calendar.isDateInToday(mostRecentEntry) {
            return 0
        }
        
        // Count consecutive days with entries
        currentDate = calendar.startOfDay(for: mostRecentEntry)
        var previousDate = currentDate
        
        for date in entryDates.dropFirst() {
            let dayDifference = calendar.dateComponents([.day], from: date, to: previousDate).day ?? 0
            if dayDifference == 1 {
                streak += 1
                previousDate = date
            } else if dayDifference > 1 {
                break
            }
        }
        
        // Add 1 to include the current day
        return streak + 1
    }
    
    private func deleteEntry(_ entry: JournalEntry) {
        if let index = journalVM.entries.firstIndex(where: { $0.id == entry.id }) {
            Task {
                await journalVM.delete(entries: [journalVM.entries[index]])
            }
        }
    }
    
    private func shareEntry(_ entry: JournalEntry) {
        let title = entry.title ?? "Journal Entry"
        let date = DateFormatter.localizedString(from: entry.createdAt, dateStyle: .medium, timeStyle: .none)
        let content = "\(title)\n\(date)\n\n\(entry.body)"
        
        let activityVC = UIActivityViewController(activityItems: [content], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

// MARK: - Supporting Views

#Preview {
    NavigationStack {
        JournalListView()
            .environmentObject(JournalViewModel())
    }
}
