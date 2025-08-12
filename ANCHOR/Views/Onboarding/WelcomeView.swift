//
//  WelcomeView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasOnboarded") var hasOnboarded = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Welcome to Anchor").font(.largeTitle).bold()
            Text("A private, on-device companion for recovery. Your data stays with you — encrypted on your device by default.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            Button("Get Started") {
                hasOnboarded = true
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
