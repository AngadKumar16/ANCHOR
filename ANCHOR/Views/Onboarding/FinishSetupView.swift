//
//  FinishSetupView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import SwiftUI

struct FinishSetupView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("All set").font(.title2).bold()
            Text("You can now make daily check-ins, write private journal entries, and use the SOS tools when you need them.")
                .multilineTextAlignment(.center)
            Button("Go to App") {
                // handled by parent flow
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
