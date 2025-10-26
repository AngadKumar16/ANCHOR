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
            Text("Risk Assessment").font(.headline)
            
            // Score display
            Text(String(format: "%d / 100", result.score))
                .font(.largeTitle)
                .bold()
                .foregroundColor(result.score > 70 ? .red : (result.score > 40 ? .orange : .green))
            
            // Risk level display
            Text("Risk Level: \(result.riskLevel.capitalized)")
                .font(.headline)
                .padding(.top, 8)
            
            // Additional information based on risk level
            if !result.responses.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your responses:")
                        .font(.headline)
                        .padding(.top, 16)
                    
                    ForEach(Array(result.responses.sorted(by: { $0.key < $1.key })), id: \.key) { key, value in
                        HStack(alignment: .top) {
                            Text("\(key):")
                                .fontWeight(.medium)
                            Text(value)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Assessment Results")
    }
}
