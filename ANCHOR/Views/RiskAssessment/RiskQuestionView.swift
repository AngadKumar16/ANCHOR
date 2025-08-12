//
//  RiskQuestionView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import SwiftUI

struct RiskQuestionView: View {
    @EnvironmentObject var viewModel: RiskAssessmentViewModel

    var body: some View {
        Form {
            Section("Mood") {
                Picker("Mood", selection: $viewModel.mood) {
                    Text("Low").tag(0)
                    Text("Neutral").tag(1)
                    Text("High").tag(2)
                }.pickerStyle(.segmented)
            }
            Section("Craving Level") {
                Slider(value: $viewModel.craving, in: 0...10, step: 1)
                Text("Craving: \(Int(viewModel.craving))")
            }
            Section("Recent triggers") {
                TextField("Comma-separated", text: $viewModel.triggersText)
            }
            Button("Calculate Risk") {
                viewModel.calculate()
            }
        }
        .navigationTitle("Questions")
        .onReceive(viewModel.$latestResult) { res in
            if res != nil {
                // show results
            }
        }
    }
}
