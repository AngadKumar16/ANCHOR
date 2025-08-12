//
//  RiskResultsView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import SwiftUI

struct RiskResultsView: View {
    let result: RiskAssessment

    var body: some View {
        VStack(spacing: 16) {
            Text("Risk Score").font(.headline)
            Text(String(format: "%.0f / 100", result.score)).font(.largeTitle).bold()
                .foregroundColor(result.score > 70 ? .red : (result.score > 40 ? .orange : .green))
            if let r = result.reason {
                Text(r).padding()
            }
            Spacer()
        }
        .padding()
        .navigationTitle("Results")
    }
}
