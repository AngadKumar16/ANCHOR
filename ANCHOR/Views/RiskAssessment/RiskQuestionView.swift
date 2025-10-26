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
            
            Section(header: Text("Triggers"),
                   footer: Text("List any triggers you've encountered (separate with commas)")) {
                TextEditor(text: $viewModel.triggersText)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .onChange(of: viewModel.triggersText) { newValue in
                        // Limit text length if needed
                        if newValue.count > 200 {
                            viewModel.triggersText = String(newValue.prefix(200))
                        }
                    }
            }
            
            Section {
                Button(action: calculateRisk) {
                    HStack {
                        if isCalculating {
                            ProgressView()
                                .padding(.trailing, 8)
                        }
                        Text("Calculate Risk Level")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid ? Color.blue : Color.gray.opacity(0.3))
                    .foregroundColor(isFormValid ? .white : .gray)
                    .cornerRadius(10)
                }
                .disabled(!isFormValid || isCalculating)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
            .padding(.vertical, 8)
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
    
    private func calculateRisk() {
        guard !viewModel.triggersText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please describe any triggers you've encountered."
            showError = true
            return
        }
        
        isCalculating = true
        
        // Calculate and save using the view model
        viewModel.calculateAndSave()
        
        // Dismiss after a short delay to allow the view model to process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isCalculating = false
            dismiss()
        }
    }
}

#Preview {
    NavigationView {
        RiskQuestionView()
            .environmentObject(RiskAssessmentViewModel(viewContext: PersistenceController.preview.container.viewContext))
    }
}
