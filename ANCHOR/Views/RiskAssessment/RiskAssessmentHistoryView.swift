//
//  RiskAssessmentHistoryView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI
import CoreData

struct RiskAssessmentHistoryView: View {
    @EnvironmentObject var viewModel: RiskAssessmentViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    
    @State private var searchText = ""
    @State private var selectedTimeFrame: TimeFrame = .allTime
    @State private var showingDeleteAlert = false
    @State private var assessmentToDelete: RiskAssessmentEntity?
    
    private enum TimeFrame: String, CaseIterable, Identifiable {
        case week = "This Week"
        case month = "This Month"
        case threeMonths = "Last 3 Months"
        case allTime = "All Time"
        
        var id: String { self.rawValue }
        
        var predicate: NSPredicate? {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .week:
                let startOfWeek = calendar.startOfDay(for: calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!)
                return NSPredicate(format: "date >= %@", startOfWeek as NSDate)
            case .month:
                let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
                return NSPredicate(format: "date >= %@", startOfMonth as NSDate)
            case .threeMonths:
                let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
                return NSPredicate(format: "date >= %@", threeMonthsAgo as NSDate)
            case .allTime:
                return nil
            }
        }
    }
    
    private var fetchRequest: FetchRequest<RiskAssessmentEntity>
    private var assessments: FetchedResults<RiskAssessmentEntity> { fetchRequest.wrappedValue }
    
    init() {
        let request: NSFetchRequest<RiskAssessmentEntity> = RiskAssessmentEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RiskAssessmentEntity.date, ascending: false)]
        _fetchRequest = FetchRequest(fetchRequest: request)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            searchAndFilterBar()
            
            if assessments.isEmpty {
                emptyStateView()
            } else {
                assessmentList()
            }
        }
        .navigationTitle("Assessment History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .alert("Delete Assessment", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let assessment = assessmentToDelete {
                    deleteAssessment(assessment)
                }
            }
        } message: {
            Text("Are you sure you want to delete this assessment? This action cannot be undone.")
        }
        .onChange(of: selectedTimeFrame) { _ in
            updateFetchRequest()
        }
    }
    
    // MARK: - View Components
    
    private func searchAndFilterBar() -> some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search assessments...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .disableAutocorrection(true)
                    .onChange(of: searchText) { _ in
                        updateFetchRequest()
                    }
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            
            // Time Frame Picker
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TimeFrame.allCases) { timeFrame in
                        Button(action: {
                            selectedTimeFrame = timeFrame
                        }) {
                            Text(timeFrame.rawValue)
                                .font(.subheadline)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(selectedTimeFrame == timeFrame ? Color.blue : Color(.systemGray5))
                                .foregroundColor(selectedTimeFrame == timeFrame ? .white : .primary)
                                .cornerRadius(15)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
    
    private func emptyStateView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "chart.bar.doc.horizontal")
                .font(.system(size: 50))
                .foregroundColor(.blue.opacity(0.5))
            
            VStack(spacing: 8) {
                Text("No Assessments Found")
                    .font(.title3)
                    .fontWeight(.medium)
                
                Text(selectedTimeFrame == .allTime ? 
                     "Complete your first risk assessment to see your history." : 
                     "No assessments found for the selected time period.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            }
            
            if selectedTimeFrame != .allTime {
                Button(action: { selectedTimeFrame = .allTime }) {
                    Text("View All Assessments")
                        .font(.subheadline)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(15)
                }
                .padding(.top, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
    
    private func assessmentList() -> some View {
        List {
            ForEach(groupedAssessments, id: \.0) { date, assessments in
                Section(header: Text(date).font(.headline)) {
                    ForEach(assessments) { assessment in
                        AssessmentRow(assessment: assessment)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                // Handle tap to view details
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    assessmentToDelete = assessment
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .background(Color(.systemGroupedBackground))
    }
    
    private var groupedAssessments: [(String, [RiskAssessmentEntity])] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        var grouped = Dictionary<String, [RiskAssessmentEntity]>()
        
        for assessment in assessments {
            let date = assessment.date
            let startOfDay = calendar.startOfDay(for: date)
            
            let dateString: String
            
            if calendar.isDateInToday(date) {
                dateString = "Today"
            } else if calendar.isDateInYesterday(date) {
                dateString = "Yesterday"
            } else if calendar.isDate(date, equalTo: today, toGranularity: .weekOfYear) {
                dateFormatter.dateFormat = "EEEE, MMM d"
                dateString = dateFormatter.string(from: date)
            } else {
                dateFormatter.dateFormat = "MMMM yyyy"
                dateString = dateFormatter.string(from: date)
            }
            
            grouped[dateString, default: []].append(assessment)
        }
        
        return grouped.sorted { (first, second) -> Bool in
            guard let firstDate = first.value.first?.date,
                  let secondDate = second.value.first?.date else {
                return false
            }
            return firstDate > secondDate
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateFetchRequest() {
        var predicates = [NSPredicate]()
        
        // Add time frame predicate
        if let timePredicate = selectedTimeFrame.predicate {
            predicates.append(timePredicate)
        }
        
        // Add search text predicate
        if !searchText.isEmpty {
            let searchPredicate = NSPredicate(format: "reason CONTAINS[cd] %@", searchText)
            predicates.append(searchPredicate)
        }
        
        let compoundPredicate = predicates.isEmpty ? nil : NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        fetchRequest.nsPredicate = compoundPredicate
    }
    
    private func deleteAssessment(_ assessment: RiskAssessmentEntity) {
        withAnimation {
            viewContext.delete(assessment)
            do {
                try viewContext.save()
            } catch {
                Logger.log("Failed to delete assessment: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Subviews

private struct AssessmentRow: View {
    let assessment: RiskAssessmentEntity
    
    private var riskColor: Color {
        switch assessment.score {
        case 0..<30: return .green
        case 30..<70: return .orange
        case 70...100: return .red
        default: return .gray
        }
    }
    
    private var riskLevel: String {
        switch assessment.score {
        case 0..<30: return "Low"
        case 30..<70: return "Medium"
        case 70...100: return "High"
        default: return "Unknown"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                // Score indicator
                ZStack {
                    Circle()
                        .stroke(lineWidth: 2)
                        .frame(width: 32, height: 32)
                        .foregroundColor(riskColor.opacity(0.3))
                    
                    Text("\(Int(assessment.score))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(riskColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(riskLevel + " Risk")
                        .font(.subheadline)
                        .foregroundColor(riskColor)
                    
                    if let reason = assessment.reason, !reason.isEmpty {
                        Text(reason)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                .padding(.leading, 8)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(assessment.date.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(assessment.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 4)
                        .opacity(0.3)
                        .foregroundColor(Color.gray)
                    
                    Rectangle()
                        .frame(width: min(CGFloat(assessment.score) / 100.0 * geometry.size.width, geometry.size.width), height: 4)
                        .foregroundColor(riskColor)
                        .animation(.linear, value: assessment.score)
                }
                .cornerRadius(2)
            }
            .frame(height: 4)
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}

// MARK: - Previews

struct RiskAssessmentHistoryView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // Create sample data
        let assessment1 = RiskAssessmentEntity(context: context)
        assessment1.id = UUID()
        assessment1.date = Date()
        assessment1.score = 25
        assessment1.reason = "Feeling good, no strong triggers"
        
        let assessment2 = RiskAssessmentEntity(context: context)
        assessment2.id = UUID()
        assessment2.date = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        assessment2.score = 65
        assessment2.reason = "Work stress, trouble sleeping"
        
        let assessment3 = RiskAssessmentEntity(context: context)
        assessment3.id = UUID()
        assessment3.date = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        assessment3.score = 80
        assessment3.reason = "High stress, strong cravings"
        
        try? context.save()
        
        return NavigationView {
            RiskAssessmentHistoryView()
                .environmentObject(RiskAssessmentViewModel())
                .environment(\.managedObjectContext, context)
        }
    }
}
