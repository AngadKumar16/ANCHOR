//
//  Color+Theme.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//

import SwiftUI

// MARK: - App Theme
enum AppTheme {
    static let primary = Color("Primary")
    static let secondary = Color("Secondary")
    static let background = Color("Background")
    static let cardBackground = Color("CardBackground")
    static let textPrimary = Color("TextPrimary")
    static let textSecondary = Color("TextSecondary")
    static let accent = Color("Accent")
    static let error = Color("Error")
    static let success = Color("Success")
    static let warning = Color("Warning")
    static let shadow = Color.black.opacity(0.1)
    
    // Gradients
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [Color("Primary"), Color("Primary").opacity(0.8)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let secondaryGradient = LinearGradient(
        gradient: Gradient(colors: [Color("Secondary"), Color("Secondary").opacity(0.7)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // For dark/light mode support
    static let adaptiveBackground = Color("AdaptiveBackground")
    static let adaptiveCard = Color("AdaptiveCard")
}

// MARK: - Color Extensions
extension Color {
    // MARK: - Initializers
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - UI Element Colors
    static let lightBackground = Color(hex: "F8F9FA")
    static let darkBackground = Color(hex: "1A1A1A")
    
    // MARK: - Text Colors
    static let lightText = Color(hex: "212529")
    static let darkText = Color(hex: "F8F9FA")
    static let secondaryText = Color(hex: "6C757D")
    
    // MARK: - Status Colors
    static let successGreen = Color(hex: "28A745")
    static let warningYellow = Color(hex: "FFC107")
    static let errorRed = Color(hex: "DC3545")
    static let infoBlue = Color(hex: "17A2B8")
    
    // MARK: - Social Colors
    static let twitterBlue = Color(hex: "1DA1F2")
    static let facebookBlue = Color(hex: "4267B2")
    static let instagramPurple = Color(hex: "E1306C")
}

// MARK: - View Modifiers for Consistent Styling
struct CardStyle: ViewModifier {
    var cornerRadius: CGFloat = 12
    var shadowRadius: CGFloat = 4
    var padding: CGFloat = 16
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(RoundedRectangle(cornerRadius: cornerRadius)
                .fill(AppTheme.cardBackground)
                .shadow(color: AppTheme.shadow, radius: shadowRadius, x: 0, y: 2)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var isFullWidth: Bool = true
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding()
            .background(AppTheme.primary.opacity(isDisabled ? 0.5 : 1.0))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .disabled(isDisabled)
    }
}

// MARK: - Text Styling Extensions
extension Text {
    func largeTitleStyle() -> some View {
        self
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(AppTheme.textPrimary)
    }
    
    func titleStyle() -> some View {
        self
            .font(.title)
            .fontWeight(.semibold)
            .foregroundColor(AppTheme.textPrimary)
    }
    
    func headlineStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(AppTheme.textPrimary)
    }
    
    func subheadlineStyle() -> some View {
        self
            .font(.subheadline)
            .foregroundColor(AppTheme.textSecondary)
    }
    
    func captionStyle() -> some View {
        self
            .font(.caption)
            .foregroundColor(AppTheme.textSecondary)
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle(cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 4, padding: CGFloat = 16) -> some View {
        modifier(CardStyle(cornerRadius: cornerRadius, shadowRadius: shadowRadius, padding: padding))
    }
    
    func primaryButton() -> some View {
        buttonStyle(PrimaryButtonStyle())
    }
    
    func secondaryButton() -> some View {
        buttonStyle(SecondaryButtonStyle())
    }
    
    func withCardAnimation<Result>(_ animation: Animation = .easeInOut(duration: 0.3), _ body: @escaping () -> Result) -> some View {
        return self.animation(animation, value: body())
    }
}

// MARK: - Secondary Button Style
struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(AppTheme.primary)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.primary, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview Provider
struct ColorTheme_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Light Mode
            VStack(spacing: 20) {
                Text("Primary")
                    .padding()
                    .background(AppTheme.primary)
                
                Text("Secondary")
                    .padding()
                    .background(AppTheme.secondary)
                
                Text("Background")
                    .padding()
                    .background(AppTheme.background)
                
                Text("Card Background")
                    .padding()
                    .background(AppTheme.cardBackground)
            }
            .previewDisplayName("Light Mode")
            .preferredColorScheme(.light)
            
            // Dark Mode
            VStack(spacing: 20) {
                Text("Primary")
                    .padding()
                    .background(AppTheme.primary)
                
                Text("Secondary")
                    .padding()
                    .background(AppTheme.secondary)
                
                Text("Background")
                    .padding()
                    .background(AppTheme.background)
                
                Text("Card Background")
                    .padding()
                    .background(AppTheme.cardBackground)
            }
            .previewDisplayName("Dark Mode")
            .preferredColorScheme(.dark)
        }
        .padding()
    }
}
