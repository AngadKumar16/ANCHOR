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
    
    @State private var mood: Int = 1
    @State private var craving: Double = 0
    @State private var triggersText: String = ""
    @State private var isCalculating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var isFormValid: Bool {
        !triggersText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        Form {
            Section(header: Text("How are you feeling?")) {
                Picker("Mood", selection: $mood) {
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
                        Text("\(Int(craving))")  
                            .font(.title3.monospacedDigit())
                            .foregroundColor(craving > 7 ? .red : .primary)
                            .animation(.easeInOut, value: craving)
                    }
                    
                    Slider(value: $craving, in: 0...10, step: 1)
                        .tint(craving > 7 ? .red : .blue)
                    
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
                TextEditor(text: $triggersText)
                    .frame(minHeight: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .onChange(of: triggersText) { newValue in
                        // Limit text length if needed
                        if newValue.count > 200 {
                            triggersText = String(newValue.prefix(200))
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
        .onAppear {
            // Sync with view model when view appears
            mood = viewModel.mood
            craving = viewModel.craving
            triggersText = viewModel.triggersText
        }
        .onChange(of: mood) { oldValue, newValue in
            viewModel.mood = newValue
        }
        .onChange(of: craving) { oldValue, newValue in
            viewModel.craving = newValue
        }
        .onChange(of: triggersText) { oldValue, newValue in
            viewModel.triggersText = newValue
        }
    }
    
    private func calculateRisk() {
        guard !triggersText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please describe any triggers you've encountered."
            showError = true
            return
        }
        
        isCalculating = true
        
        // Update view model
        viewModel.mood = mood
        viewModel.craving = craving
        viewModel.triggersText = triggersText
        
        // Simulate network/database operation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            viewModel.calculateAndSave()
            isCalculating = false
            dismiss()
        }
    }
}

#Preview {
    NavigationView {
        RiskQuestionView()
            .environmentObject(RiskAssessmentViewModel())
    }
}
