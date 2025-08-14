//
//  RiskAssessmentHistoryView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

struct RiskAssessmentHistoryView: View {
    @EnvironmentObject var viewModel: RiskAssessmentViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedAssessment: RiskAssessmentEntity?
    @State private var showingDeleteAlert = false
    @State private var assessmentToDelete: RiskAssessmentEntity?
    
    var body: some View {
        List {
            if viewModel.fetchRecent(limit: 100).isEmpty {
                emptyStateView()
            } else {
                assessmentsList()
            }
        }
        .navigationTitle("Assessment History")
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
    }
    
    @ViewBuilder
    private func emptyStateView() -> some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No Assessments Yet")
                    .font(.headline)
                
                Text("Complete your first risk assessment to see your history here.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            Button(action: { dismiss() }) {
                Text("New Assessment")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)
        }
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private func assessmentsList() -> some View {
        ForEach(viewModel.fetchRecent(limit: 100)) { assessment in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(assessment.date.formatted(date: .complete, time: .shortened))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(assessment.score))%")
                        .font(.headline)
                        .foregroundColor(riskColor(score: assessment.score))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(riskColor(score: assessment.score).opacity(0.2))
                        .cornerRadius(12)
                }
                
                if let reason = assessment.reason, !reason.isEmpty {
                    Text(reason)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 8)
            .swipeActions(edge: .trailing) {
                Button(role: .destructive) {
                    assessmentToDelete = assessment
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }
    
    private func riskColor(score: Double) -> Color {
        switch score {
        case 0..<30: return .green
        case 30..<70: return .orange
        case 70...100: return .red
        default: return .gray
        }
    }
    
    private func deleteAssessment(_ assessment: RiskAssessmentEntity) {
        let context = PersistenceController.shared.container.viewContext
        context.delete(assessment)
        
        do {
            try context.save()
        } catch {
            print("Failed to delete assessment: \(error)")
        }
    }
}

#Preview {
    NavigationView {
        RiskAssessmentHistoryView()
            .environmentObject(RiskAssessmentViewModel())
    }
}
