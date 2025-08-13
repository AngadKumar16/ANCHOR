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
    
    private let riskLevels: [Double: (String, Color)] = [
        0..<30: ("Low", .green),
        30..<70: ("Medium", .orange),
        70...100: ("High", .red)
    ]
    
    private var recentAssessments: [RiskAssessmentEntity] {
        viewModel.fetchRecent(limit: 5)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Risk Summary Card
                    VStack(spacing: 16) {
                        Text("Current Risk Level")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        if let latest = recentAssessments.first {
                            RiskGauge(score: latest.score)
                            
                            VStack(spacing: 8) {
                                Text("\(Int(latest.score))%")
                                    .font(.system(size: 48, weight: .bold, design: .rounded))
                                
                                Text(riskLevel(for: latest.score).0 + " Risk")
                                    .font(.title3)
                                    .foregroundColor(riskLevel(for: latest.score).1)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(riskLevel(for: latest.score).1.opacity(0.2))
                                    .cornerRadius(20)
                                
                                if let date = latest.date {
                                    Text("Last assessed: \(date.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        } else {
                            Text("No assessments yet")
                                .foregroundColor(.secondary)
                        }
                        
                        Button(action: { showingNewAssessment = true }) {
                            Label("New Assessment", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.top, 8)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Recent Assessments
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Assessments")
                                .font(.headline)
                            Spacer()
                            Button("See All") { showHistory = true }
                                .font(.subheadline)
                        }
                        .padding(.horizontal)
                        
                        if recentAssessments.isEmpty {
                            Text("No assessments yet. Complete your first assessment to see your history.")
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding()
                        } else {
                            ForEach(recentAssessments.prefix(3)) { assessment in
                                RiskHistoryRow(assessment: assessment)
                            }
                        }
                    }
                    .padding(.top, 8)
                    
                    // Quick Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Tips")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            TipCard(
                                icon: "exclamationmark.triangle.fill",
                                title: "High Risk?",
                                description: "Reach out to your support network or healthcare provider if you're feeling at risk."
                            )
                            
                            TipCard(
                                icon: "hand.raised.fill",
                                title: "Triggers",
                                description: "Identify and avoid triggers that may lead to substance use."
                            )
                            
                            TipCard(
                                icon: "heart.fill",
                                title: "Self Care",
                                description: "Practice self-care activities to manage stress and cravings."
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                }
                .padding(.vertical)
            }
            .navigationTitle("Risk Assessment")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showHistory = true }) {
                        Image(systemName: "clock.arrow.circlepath")
                    }
                }
            }
            .sheet(isPresented: $showingNewAssessment) {
                NavigationView {
                    RiskQuestionView()
                        .environmentObject(viewModel)
                        .navigationTitle("New Assessment")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
            .sheet(isPresented: $showHistory) {
                NavigationView {
                    RiskAssessmentHistoryView()
                        .environmentObject(viewModel)
                        .navigationTitle("Assessment History")
                        .navigationBarTitleDisplayMode(.inline)
                }
            }
        }
    }
    
    private func riskLevel(for score: Double) -> (String, Color) {
        for (range, level) in riskLevels {
            if range.contains(score) {
                return level
            }
        }
        return ("Unknown", .gray)
    }
}

private struct RiskGauge: View {
    let score: Double
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20)
                .opacity(0.3)
                .foregroundColor(.gray)
            
            Circle()
                .trim(from: 0.0, to: min(score/100, 1.0))
                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                .fill(score < 30 ? .green : score < 70 ? .orange : .red)
                .rotationEffect(Angle(degrees: -90))
                .animation(.easeInOut, value: score)
        }
        .frame(width: 180, height: 180)
        .padding()
    }
}

private struct RiskHistoryRow: View {
    let assessment: RiskAssessmentEntity
    
    private func riskColor(score: Double) -> Color {
        switch score {
        case 0..<30: return .green
        case 30..<70: return .orange
        case 70...100: return .red
        default: return .gray
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let date = assessment.date {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                if let reason = assessment.reason {
                    Text(reason)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text("\(Int(assessment.score))%")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(riskColor(score: assessment.score))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(riskColor(score: assessment.score).opacity(0.2))
                .cornerRadius(12)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

private struct TipCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    RiskAssessmentView()
        .environmentObject(RiskAssessmentViewModel())
}
