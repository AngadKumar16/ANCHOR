//
//  RiskAssessmentView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import SwiftUI

struct RiskAssessmentView: View {
    @EnvironmentObject var viewModel: RiskAssessmentViewModel
    @State private var showResults = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Quick Risk Assessment").font(.title2).bold()
                Text("Answer a few quick questions to estimate near-term relapse risk.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                NavigationLink("Start Assessment", destination: RiskQuestionView().environmentObject(viewModel))
                    .buttonStyle(.borderedProminent)
                    .padding()
                Spacer()
            }
            .navigationTitle("Risk")
        }
    }
}
