//
//  RiskQuestionView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import SwiftUI

struct RiskQuestionView: View {
    @EnvironmentObject var viewModel: RiskAssessmentViewModel
    
    // Create local state bindings that sync with the view model
    @State private var mood: Int
    @State private var craving: Double
    @State private var triggersText: String
    
    init() {
        // Initialize with default values that will be updated when the view appears
        _mood = State(initialValue: 1)
        _craving = State(initialValue: 0)
        _triggersText = State(initialValue: "")
    }

    var body: some View {
        Form {
            Section("Mood") {
                Picker("Mood", selection: $mood) {
                    Text("Low").tag(0)
                    Text("Neutral").tag(1)
                    Text("High").tag(2)
                }
                .pickerStyle(.segmented)
            }
            
            Section("Craving Level (0-10)") {
                Slider(value: $craving, in: 0...10, step: 1)
                Text("Craving: \(Int(craving))")
                    .font(.headline)
                    .foregroundColor(craving > 7 ? .red : .primary)
            }
            
            Section("Recent Triggers") {
                TextField("Comma-separated list", text: $triggersText)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            
            Section {
                Button(action: calculateRisk) {
                    HStack {
                        Spacer()
                        Text("Calculate Risk")
                            .font(.headline)
                        Spacer()
                    }
                }
                .buttonStyle(.borderedProminent)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("Risk Assessment")
        .navigationBarTitleDisplayMode(.inline)
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
        viewModel.mood = mood
        viewModel.craving = craving
        viewModel.triggersText = triggersText
        viewModel.calculateAndSave()
    }
}

#Preview {
    NavigationView {
        RiskQuestionView()
            .environmentObject(RiskAssessmentViewModel())
    }
}
