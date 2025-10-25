import SwiftUI
import CoreData
import Charts

struct MoodHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var selectedMood: MoodEntity?
    @State private var showingMoodDetail = false
    
    private var moods: [MoodEntity] {
        let request = MoodEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MoodEntity.date, ascending: false)]
        
        // Apply time frame filter
        if let predicate = selectedTimeFrame.predicate {
            request.predicate = predicate
        }
        
        do {
            return try viewContext.fetch(request)
        } catch {
            Logger.persistence.error("Failed to fetch moods: \(error.localizedDescription)")
            return []
        }
    }
    
    private var averageMood: Double? {
        guard !moods.isEmpty else { return nil }
        let sum = moods.reduce(0) { $0 + Double($1.level) }
        return sum / Double(moods.count)
    }
    
    private var averageMoodLevel: MoodLevel? {
        guard let average = averageMood else { return nil }
        let roundedAverage = Int16(round(average))
        return MoodLevel(rawValue: roundedAverage) ?? .okay
    }
    
    var body: some View {
        NavigationView {
            Group {
                if moods.isEmpty {
                    emptyStateView()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Mood Summary
                            moodSummaryView()
                            
                            // Mood Chart
                            moodChartView()
                                .frame(height: 200)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(16)
                                .padding(.horizontal)
                            
                            // Mood List
                            moodListView()
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Mood History")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Picker("Time Frame", selection: $selectedTimeFrame) {
                        ForEach(TimeFrame.allCases) { frame in
                            Text(frame.rawValue).tag(frame)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                }
            }
            .sheet(item: $selectedMood) { mood in
                MoodDetailView(mood: mood)
            }
        }
    }
    
    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 50))
                .foregroundColor(.blue.opacity(0.5))
            
            Text("No Mood Entries")
                .font(.headline)
            
            Text("Track your mood to see your history and trends here.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    @ViewBuilder
    private func moodSummaryView() -> some View {
        VStack(spacing: 16) {
            if let averageLevel = averageMoodLevel {
                HStack(spacing: 8) {
                    Text("Average Mood:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(averageLevel.emoji)
                        .font(.title2)
                    
                    Text(averageLevel.description)
                        .font(.headline)
                        .foregroundColor(averageLevel.color)
                }
            }
            
            HStack(spacing: 16) {
                ForEach(MoodLevel.allCases) { level in
                    let count = moods.filter { $0.moodLevel == level }.count
                    if count > 0 {
                        VStack {
                            Text("\(count)")
                                .font(.headline)
                            
                            Text(level.emoji)
                                .font(.title3)
                                .frame(width: 44, height: 44)
                                .background(level.color.opacity(0.2))
                                .clipShape(Circle())
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .padding()
        }
        .padding(.top)
    }
    
    @ViewBuilder
    private func moodChartView() -> some View {
        Chart {
            ForEach(moods.reversed()) { mood in
                LineMark(
                    x: .value("Date", mood.date, unit: selectedTimeFrame.chartUnit),
                    y: .value("Mood", mood.level)
                )
                .foregroundStyle(mood.moodLevel.color.gradient)
                .interpolationMethod(.catmullRom)
                
                PointMark(
                    x: .value("Date", mood.date, unit: selectedTimeFrame.chartUnit),
                    y: .value("Mood", mood.level)
                )
                .foregroundStyle(mood.moodLevel.color)
                .symbolSize(60)
            }
            
            if let average = averageMood {
                RuleMark(y: .value("Average", average))
                    .foregroundStyle(.gray)
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                    .annotation(position: .leading) {
                        Text("Avg: \(String(format: "%.1f", average))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(4)
                            .background(Color(.systemBackground).opacity(0.8))
                            .cornerRadius(4)
                    }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                if let date = value.as(Date.self) {
                    AxisValueLabel {
                        Text(selectedTimeRangeFormatter.string(from: date))
                            .font(.caption2)
                    }
                }
                AxisGridLine()
                AxisTick()
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [1, 2, 3, 4, 5]) { value in
                if let level = value.as(Int.self) {
                    AxisValueLabel {
                        if let moodLevel = MoodLevel(rawValue: Int16(level)) {
                            Text(moodLevel.emoji)
                                .font(.caption)
                        }
                    }
                }
                AxisGridLine()
                AxisTick()
            }
        }
    }
    
    @ViewBuilder
    private func moodListView() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Entries")
                .font(.headline)
                .padding(.horizontal)
            
            VStack(spacing: 8) {
                ForEach(moods) { mood in
                    Button(action: {
                        selectedMood = mood
                    }) {
                        MoodRow(mood: mood)
                            .padding(.horizontal)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if mood != moods.last {
                        Divider()
                            .padding(.leading, 60)
                    }
                }
            }
            .padding(.vertical, 8)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
    
    private var selectedTimeRangeFormatter: DateFormatter {
        let formatter = DateFormatter()
        switch selectedTimeFrame {
        case .week:
            formatter.dateFormat = "E"
        case .month:
            formatter.dateFormat = "MMM d"
        case .threeMonths, .sixMonths:
            formatter.dateFormat = "MMM"
        case .year, .allTime:
            formatter.dateFormat = "MMM yyyy"
        }
        return formatter
    }
}

// MARK: - Time Frame

enum TimeFrame: String, CaseIterable, Identifiable {
    case week = "Week"
    case month = "Month"
    case threeMonths = "3 Months"
    case sixMonths = "6 Months"
    case year = "Year"
    case allTime = "All Time"
    
    var id: String { self.rawValue }
    
    var predicate: NSPredicate? {
        let calendar = Calendar.current
        let now = Date()
        
        switch self {
        case .week:
            let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
            return NSPredicate(format: "date >= %@", startOfWeek as NSDate)
        case .month:
            let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
            return NSPredicate(format: "date >= %@", startOfMonth as NSDate)
        case .threeMonths:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
            return NSPredicate(format: "date >= %@", threeMonthsAgo as NSDate)
        case .sixMonths:
            let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now)!
            return NSPredicate(format: "date >= %@", sixMonthsAgo as NSDate)
        case .year:
            let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now))!
            return NSPredicate(format: "date >= %@", startOfYear as NSDate)
        case .allTime:
            return nil
        }
    }
    
    var chartUnit: Calendar.Component {
        switch self {
        case .week, .month:
            return .day
        case .threeMonths, .sixMonths, .year:
            return .month
        case .allTime:
            return .month
        }
    }
}

// MARK: - Mood Detail View

struct MoodDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    let mood: MoodEntity
    @State private var showingDeleteAlert = false
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .short
        return formatter.string(from: mood.date)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Mood Emoji
                    Text(mood.moodLevel.emoji)
                        .font(.system(size: 80))
                        .frame(width: 120, height: 120)
                        .background(mood.moodLevel.color.opacity(0.2))
                        .clipShape(Circle())
                        .padding(.top, 32)
                    
                    // Mood Level
                    Text(mood.moodLevel.description)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(mood.moodLevel.color)
                    
                    // Date
                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Note
                    if let note = mood.note, !note.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text(note)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                        }
                        .padding()
                    }
                    
                    Spacer()
                    
                    // Delete Button
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete Entry", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                    }
                    .padding()
                }
                .padding()
            }
            .navigationTitle("Mood Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Delete Mood Entry", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteMood()
                }
            } message: {
                Text("Are you sure you want to delete this mood entry? This action cannot be undone.")
            }
        }
    }
    
    private func deleteMood() {
        viewContext.delete(mood)
        do {
            try viewContext.save()
            dismiss()
        } catch {
            Logger.persistence.error("Failed to delete mood: \(error.localizedDescription)")
        }
    }
}

// MARK: - Previews

struct MoodHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // Add sample data
        for i in 0..<30 {
            let mood = MoodEntity(context: context)
            mood.id = UUID()
            mood.date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) ?? Date()
            mood.level = Int16(Int.random(in: 1...5))
            if i % 3 == 0 {
                mood.note = "Sample mood entry for testing"
            }
        }
        
        return MoodHistoryView()
            .environment(\.managedObjectContext, context)
    }
}

struct MoodDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let mood = MoodEntity(context: context)
        mood.id = UUID()
        mood.date = Date()
        mood.level = 4
        mood.note = "This is a sample mood note for preview purposes. It contains some details about how I was feeling at this moment."
        
        return MoodDetailView(mood: mood)
            .environment(\.managedObjectContext, context)
    }
}
