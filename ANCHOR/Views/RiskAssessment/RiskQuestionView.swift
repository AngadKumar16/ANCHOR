//
//  RiskQuestionView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//

import SwiftUI

struct RiskQuestionView: View {
    @EnvironmentObject var viewModel: RiskAssessmentViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var isCalculating = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSaving = false
    
    private var isFormValid: Bool {
        !viewModel.triggersText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section(header: Text("How are you feeling?")) {
                Picker("Mood", selection: $viewModel.mood) {
                    Text("😔 Low").tag(0)
                    Text("😐 Neutral").tag(1)
                    Text("😊 High").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.vertical, 4)
            }
            
            Section(header: Text("Craving Level"), 
                    footer: Text("Rate your current craving level from 0 (no craving) to 10 (strong craving)")) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Craving:")
                            .font(.headline)
                        Spacer()
                        Text("\(Int(viewModel.craving))")
                            .font(.title3.monospacedDigit())
                            .foregroundColor(viewModel.craving > 7 ? .red : .primary)
                            .animation(.easeInOut, value: viewModel.craving)
                    }
                    
                    Slider(value: $viewModel.craving, in: 0...10, step: 1)
                        .tint(viewModel.craving > 7 ? .red : .blue)
                    
                    HStack {
                        Text("None")
                        Spacer()
                        Text("Moderate")
                        Spacer()
                        Text("Intense")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section(header: Text("Triggers")) {
                TextEditor(text: $viewModel.triggersText)
                    .frame(minHeight: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            }
            
            Section {
                Button(action: {
                    Task {
                        await calculateRisk()
                    }
                }) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Calculate Risk")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isFormValid || isSaving)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 8)
            }
        }
        .navigationTitle("New Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func calculateRisk() async {
        guard !viewModel.triggersText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            await MainActor.run {
                errorMessage = "Please describe any triggers you've encountered."
                showError = true
            }
            return
        }
        
        await MainActor.run {
            isSaving = true
        }
        
        do {
            try await viewModel.calculateAndSave()
            
            await MainActor.run {
                isSaving = false
                dismiss()
            }
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = "Failed to save assessment: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

#Preview {
    NavigationView {
        RiskQuestionView()
            .environmentObject(RiskAssessmentViewModel.preview)
    }
}
