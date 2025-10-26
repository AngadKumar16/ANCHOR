import SwiftUI
//import ANCHORDesign

struct JournalListView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @State private var showingNewEntry = false
    @State private var searchText = ""
    @State private var selectedMoodFilter: MoodFilter = .all
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: JournalEntryModel?
    
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
                ANCHORDesign.Colors.background
                    .ignoresSafeArea()
                
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
            .toolbarBackground(ANCHORDesign.Colors.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
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
                NavigationView {
                    JournalEntryView()
                }
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
        .padding(ANCHORDesign.Spacing.md)
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
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(ANCHORDesign.Colors.textSecondary)
            
            TextField("Search journal entries", text: $searchText)
                .textFieldStyle(.plain)
            
            if !searchText.isEmpty {
                Button(action: { searchText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(ANCHORDesign.Colors.textSecondary)
                }
            }
        }
        .padding(ANCHORDesign.Spacing.sm)
        .background(ANCHORDesign.Colors.backgroundSecondary)
        .cornerRadius(ANCHORDesign.CornerRadius.medium)
    }
    
    private var moodFilterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: ANCHORDesign.Spacing.sm) {
                ForEach(MoodFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation(.spring()) {
                            selectedMoodFilter = filter
                        }
                    }) {
                        HStack(spacing: ANCHORDesign.Spacing.xs) {
                            Image(systemName: filter.icon)
                            Text(filter.rawValue)
                                .font(.caption)
                        }
                        .padding(.horizontal, ANCHORDesign.Spacing.md)
                        .padding(.vertical, ANCHORDesign.Spacing.xs)
                        .background(selectedMoodFilter == filter ? filter.color.opacity(0.2) : ANCHORDesign.Colors.backgroundSecondary)
                        .foregroundColor(selectedMoodFilter == filter ? filter.color : ANCHORDesign.Colors.textPrimary)
                        .cornerRadius(ANCHORDesign.CornerRadius.large)
                        .overlay(
                            RoundedRectangle(cornerRadius: ANCHORDesign.CornerRadius.large)
                                .stroke(selectedMoodFilter == filter ? filter.color : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.vertical, ANCHORDesign.Spacing.xs)
        }
    }
    
    private var statsSection: some View {
        HStack(spacing: ANCHORDesign.Spacing.lg) {
            StatView(
                value: "\(journalVM.entries.count)",
                label: "Entries",
                icon: "book.fill",
                color: ANCHORDesign.Colors.primary
            )
            
            Divider()
                .frame(height: 40)
            
            StatView(
                value: "\(writingStreak)",
                label: "Day Streak",
                icon: "flame.fill",
                color: .orange
            )
        }
        .padding(.vertical, ANCHORDesign.Spacing.sm)
    }
    
    // MARK: - Journal Entries List Components
    
    private func monthSection(month: String, entries: [JournalEntry]) -> some View {
        Section(header: 
            HStack {
                Text(month)
                    .font(.headline)
                    .foregroundColor(ANCHORDesign.Colors.primary) // Primary color for month headers
                Spacer()
            }
            .padding(.vertical, 4)
            .background(ANCHORDesign.Colors.backgroundPrimary)
        ) {
            ForEach(entries) { entry in
                journalEntryRow(entry: entry)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(ANCHORDesign.Colors.backgroundCard)
                            .shadow(color: ANCHORDesign.Colors.primary.opacity(0.05), radius: 3, x: 0, y: 2)
                    )
                    .padding(.vertical, 4)
            }
        }
        .listRowInsets(EdgeInsets(
            top: 4,
            leading: 16,
            bottom: 4,
            trailing: 16
        ))
    }
    
    private func journalEntryRow(entry: JournalEntry) -> some View {
        NavigationLink(destination: JournalDetailView(viewModel: journalVM, entry: entry)) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.title ?? "Untitled Entry")
                        .font(.headline)
                        .foregroundColor(ANCHORDesign.Colors.textPrimary)
                    
                    Spacer()
                    
                    // Mood indicator dot
                    Circle()
                        .fill(moodColor(for: entry.sentiment ?? 0))
                        .frame(width: 8, height: 8)
                }
                
                Text(entry.body)
                    .font(.subheadline)
                    .foregroundColor(ANCHORDesign.Colors.textSecondary)
                    .lineLimit(2)
                
                HStack {
                    Text(entry.createdAt, style: .date)
                        .font(.caption2)
                        .foregroundColor(ANCHORDesign.Colors.primary.opacity(0.7)) // Subtle primary color for date
                    
                    if !entry.tags.isEmpty {
                        Text(entry.tags.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundColor(ANCHORDesign.Colors.accent) // Accent color for tags
                            .lineLimit(1)
                    }
                }
                .padding(.top, 2)
            }
            .padding(12)
        }
        .listRowBackground(Color.clear)
    }
    
    private func moodColor(for sentiment: Double) -> Color {
        switch sentiment {
        case ..<(-0.3):
            return ANCHORDesign.Colors.error.opacity(0.7)
        case -0.3..<0.3:
            return ANCHORDesign.Colors.warning.opacity(0.7)
        default:
            return ANCHORDesign.Colors.success.opacity(0.7)
        }
    }
    
    // MARK: - Journal Entries List
    
    private var journalEntriesList: some View {
        List {
            ForEach(groupedEntries, id: \.0) { month, entries in
                monthSection(month: month, entries: entries)
            }
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        }
        .listStyle(.plain)
        .background(ANCHORDesign.Colors.backgroundPrimary)
        .scrollContentBackground(.hidden)
        .safeAreaInset(edge: .bottom) {
            // Very subtle bottom bar
            Color.clear
                .frame(height: 0.2)
                .background(ANCHORDesign.Colors.primary.opacity(0.1))
        }
        .animation(.easeInOut(duration: 0.15), value: groupedEntries.count)
    }
    
    // MARK: - Empty State View
    
    private var emptyStateView: some View {
        VStack(spacing: ANCHORDesign.Spacing.lg) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 60))
                .foregroundColor(ANCHORDesign.Colors.primary.opacity(0.2))
            
            VStack(spacing: ANCHORDesign.Spacing.xs) {
                Text("No Entries Yet")
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(ANCHORDesign.Colors.textPrimary)
                
                Text("Start journaling to track your thoughts and progress")
                    .font(.subheadline)
                    .foregroundColor(ANCHORDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, ANCHORDesign.Spacing.xl)
            }
            
            Button(action: { showingNewEntry = true }) {
                Text("New Entry")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, ANCHORDesign.Spacing.xl)
                    .padding(.vertical, ANCHORDesign.Spacing.md)
                    .background(ANCHORDesign.Colors.primary)
                    .cornerRadius(ANCHORDesign.CornerRadius.medium)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
            }
            .buttonStyle(ScaleButtonStyle())
            .padding(.top, ANCHORDesign.Spacing.sm)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, 100)
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
    
    // MARK: - StatView Component
    
    private struct StatView: View {
        let value: String
        let label: String
        let icon: String
        let color: Color
        
        var body: some View {
            VStack(spacing: 4) {
                HStack(alignment: .center, spacing: ANCHORDesign.Spacing.xs) {
                    Image(systemName: icon)
                        .font(.subheadline)
                        .foregroundColor(color)
                    
                    Text(value)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(ANCHORDesign.Colors.textPrimary)
                }
                
                Text(label)
                    .font(.caption)
                    .foregroundColor(ANCHORDesign.Colors.textSecondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    // MARK: - JournalEntryRow Component
    
    private struct JournalEntryRow: View {
        let entry: JournalEntry
        
        private var moodColor: Color {
            guard let sentiment = entry.sentiment else { 
                return ANCHORDesign.Colors.textSecondary 
            }
            if sentiment > 0.3 {
                return ANCHORDesign.Colors.moodHappy
            } else if sentiment < -0.3 {
                return ANCHORDesign.Colors.moodSad
            } else {
                return ANCHORDesign.Colors.moodNeutral
            }
        }
        
        private var formattedDate: String {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: entry.createdAt)
        }
        
        private var titleView: some View {
            Text(entry.title ?? "Untitled Entry")
                .font(.headline)
                .foregroundColor(ANCHORDesign.Colors.textPrimary)
                .lineLimit(1)
        }
        
        private var bodyPreview: some View {
            Text(entry.body)
                .font(.subheadline)
                .foregroundColor(ANCHORDesign.Colors.textSecondary)
                .lineLimit(2)
        }
        
        private var dateView: some View {
            Text(formattedDate)
                .font(.caption2)
                .foregroundColor(ANCHORDesign.Colors.textTertiary)
        }
        
        private var moodIndicator: some View {
            Circle()
                .fill(moodColor)
                .frame(width: 8, height: 8)
                .shadow(color: moodColor.opacity(0.5), radius: 2, x: 0, y: 1)
        }
        
        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        titleView
                        bodyPreview
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        dateView
                        moodIndicator
                    }
                }
                .padding(ANCHORDesign.Spacing.sm)
                .background(ANCHORDesign.Colors.backgroundCard)
                .cornerRadius(ANCHORDesign.CornerRadius.medium)
                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
        }
    }
    
    // MARK: - Context Menu
    
    private func contextMenuForEntry(_ entry: JournalEntryModel) -> some View {
        Group {
            Button(action: {
                // Handle edit
                showingNewEntry = true
                // You might want to pass the entry to an edit view here
            }) {
                Label("Edit", systemImage: "pencil")
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
    
    private func deleteEntry(_ entry: JournalEntryModel) {
        Task {
            do {
                // Convert JournalEntryModel back to JournalEntry if needed
                if let journalEntry = journalVM.entries.first(where: { $0.id == entry.id }) {
                    try await journalVM.delete(entries: [journalEntry])
                }
            } catch {
                // Handle error appropriately in your UI
                print("Error deleting entry: \(error.localizedDescription)")
            }
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
