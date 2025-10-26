//
//  ButtonStyles.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

/// A button style that applies a scale effect when pressed
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut, value: configuration.isPressed)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        Button(action: {}) {
            Text("Press Me")
                .padding()
                .background(Color(uiColor: .systemBlue))
                .foregroundColor(Color.white)
                .cornerRadius(8)
        }
        .buttonStyle(ScaleButtonStyle())
    }
    .padding()
}
