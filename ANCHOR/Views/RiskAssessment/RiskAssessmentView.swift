//
//  RiskAssessmentView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//

import SwiftUI

struct RiskAssessmentView: View {
    @EnvironmentObject var viewModel: RiskAssessmentViewModel
    @State private var showHistory = false
    @State private var showingNewAssessment = false
    @State private var selectedTab = 0
    
    private let riskLevels: [ClosedRange<Double>: (String, Color, String)] = [
        0..<30: ("Low", .green, "You're doing great! Keep up the good work."),
        30..<70: ("Medium", .orange, "Be mindful of your triggers and practice healthy coping strategies."),
        70...100: ("High", .red, "Consider reaching out for support and using your coping strategies.")
    ]
    
    private var recentAssessments: [RiskAssessmentEntity] {
        viewModel.fetchRecent(limit: 5)
    }
    
    private var latestAssessment: RiskAssessmentEntity? {
        recentAssessments.first
    }
    
    private var riskLevel: (String, Color, String) {
        if let latest = latestAssessment {
            for (range, level) in riskLevels {
                if range.contains(latest.score) {
                    return level
                }
            }
        }
        return ("Not Assessed", .gray, "Complete an assessment to see your risk level.")
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    riskSummaryCard()
                    
                    if let latest = latestAssessment {
                        VStack(spacing: 16) {
                            Text("Recommendations")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                            
                            Text(riskLevel.2)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .padding(.horizontal)
                        }
                    }
                    
                    recentAssessmentsSection()
                    
                    if !recentAssessments.isEmpty {
                        quickTipsSection()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Risk Assessment")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showHistory = true }) {
                        Label("History", systemImage: "clock.arrow.circlepath")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingNewAssessment = true }) {
                        Label("New Assessment", systemImage: "plus.circle")
                    }
                }
            }
            .sheet(isPresented: $showingNewAssessment) {
                NavigationView {
                    RiskQuestionView()
                        .environmentObject(viewModel)
                }
            }
            .sheet(isPresented: $showHistory) {
                NavigationView {
                    RiskAssessmentHistoryView()
                        .environmentObject(viewModel)
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private func riskSummaryCard() -> some View {
        VStack(spacing: 16) {
            if let latest = latestAssessment {
                // Risk Gauge
                ZStack {
                    Circle()
                        .stroke(lineWidth: 20)
                        .opacity(0.3)
                        .foregroundColor(riskLevel.1.opacity(0.3))
                    
                    Circle()
                        .trim(from: 0.0, to: min(CGFloat(latest.score) / 100.0, 1.0))
                        .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                        .foregroundColor(riskLevel.1)
                        .rotationEffect(Angle(degrees: -90))
                        .animation(.easeInOut, value: latest.score)
                    
                    VStack(spacing: 8) {
                        Text("\(Int(latestAssessment?.score ?? 0))%")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(riskLevel.1)
                        
                        Text(riskLevel.0 + " Risk")
                            .font(.title3)
                            .foregroundColor(riskLevel.1)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(riskLevel.1.opacity(0.2))
                            .cornerRadius(20)
                        
                        Text("Last assessed: \(latest.date.formatted(date: .abbreviated, time: .shortened))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: 250, height: 250)
                .padding()
                
                if let reason = latest.reason, !reason.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Factors Considered:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(reason)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("No Assessments Yet")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    Text("Complete your first risk assessment to track your progress and get personalized recommendations.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                    
                    Button(action: { showingNewAssessment = true }) {
                        Label("Start Assessment", systemImage: "plus.circle")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 10)
                }
                .padding(.vertical, 40)
                .padding(.horizontal)
            }
        }
    }
    
    private func recentAssessmentsSection() -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Recent Assessments")
                    .font(.headline)
                
                Spacer()
                
                if !recentAssessments.isEmpty {
                    Button("See All") {
                        showHistory = true
                    }
                    .font(.subheadline)
                }
            }
            .padding(.horizontal)
            
            if recentAssessments.isEmpty {
                Text("No recent assessments")
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(Array(recentAssessments.prefix(3).enumerated()), id: \.element.id) { index, assessment in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(assessment.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            if let level = riskLevels.first(where: { $0.key.contains(assessment.score) })?.value {
                                Text(level.0)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(level.1.opacity(0.2))
                                    .foregroundColor(level.1)
                                    .cornerRadius(8)
                            }
                        }
                        
                        if let reason = assessment.reason, !reason.isEmpty {
                            Text(reason)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        if index < min(2, recentAssessments.count - 1) {
                            Divider()
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func quickTipsSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Tips")
                .font(.headline)
                .padding(.horizontal)
            
            let tips = [
                "Practice deep breathing exercises",
                "Reach out to your support network",
                "Engage in a distracting activity",
                "Review your coping strategies",
                "Take a short walk if possible"
            ]
            
            VStack(spacing: 12) {
                ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lightbulb.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 16))
                        
                        Text(tip)
                            .font(.subheadline)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    if index < tips.count - 1 {
                        Divider()
                            .padding(.leading, 40)
                            .padding(.trailing)
                    }
                }
            }
            .padding(.vertical, 12)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

#Preview {
    let viewModel = RiskAssessmentViewModel()
    // Add sample data for preview
    let context = PersistenceController.preview.container.viewContext
    
    // Create sample assessments
    let assessment1 = RiskAssessmentEntity(context: context)
    assessment1.id = UUID()
    assessment1.date = Date().addingTimeInterval(-86400) // Yesterday
    assessment1.score = 25
    assessment1.reason = "Low stress, no strong triggers"
    
    let assessment2 = RiskAssessmentEntity(context: context)
    assessment2.id = UUID()
    assessment2.date = Date()
    assessment2.score = 65
    assessment2.reason = "Moderate stress, work pressure, lack of sleep"
    
    try? context.save()
    
    return RiskAssessmentView()
        .environmentObject(viewModel)
        .environment(\.managedObjectContext, context)
}
