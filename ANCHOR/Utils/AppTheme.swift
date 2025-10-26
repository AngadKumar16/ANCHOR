//
//  AppTheme.swift
//  ANCHOR
//
//  This file provides backward compatibility for existing code.
//  New code should use ANCHORDesign directly.
//

import SwiftUI

// MARK: - App Theme (Legacy)

/// Legacy theme system - use ANCHORDesign for new code
enum AppTheme {
    // MARK: - Colors
    static let primary = Color.anchorPrimary
    static let secondary = Color.blue
    static let background = Color(UIColor.systemBackground)
    static let cardBackground = Color(UIColor.secondarySystemBackground)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    
    // MARK: - Shadows
    struct ShadowStyle {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
    }
    
    static let shadow = Color.black.opacity(0.1)
    static let cardShadow = ShadowStyle(
        color: shadow,
        radius: 8,
        x: 0,
        y: 2
    )
    
    // MARK: - Button Styles
    struct PrimaryButtonStyle: ButtonStyle {
        @Environment(\.isEnabled) private var isEnabled: Bool
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .background(primary)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .opacity(isEnabled ? 1.0 : 0.5)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
        }
    }
    
    struct SecondaryButtonStyle: ButtonStyle {
        @Environment(\.isEnabled) private var isEnabled: Bool
        
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .padding()
                .background(background)
                .foregroundColor(primary)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(primary, lineWidth: 1)
                )
                .opacity(isEnabled ? 1.0 : 0.5)
                .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
        }
    }
}

// MARK: - Preview Provider

struct AppTheme_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Color Samples
            HStack(spacing: 10) {
                ColorSampleView(color: AppTheme.primary, name: "Primary")
                ColorSampleView(color: AppTheme.secondary, name: "Secondary")
                ColorSampleView(color: AppTheme.background, name: "Background")
            }
            
            // Button Samples
            VStack(spacing: 10) {
                Button("Primary Button") {}
                    .buttonStyle(AppTheme.PrimaryButtonStyle())
                
                Button("Secondary Button") {}
                    .buttonStyle(AppTheme.SecondaryButtonStyle())
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

// MARK: - Helper View

private struct ColorSampleView: View {
    let color: Color
    let name: String
    
    var body: some View {
        VStack {
            color
                .frame(width: 60, height: 60)
                .cornerRadius(8)
            Text(name)
                .font(.caption)
        }
    }
}