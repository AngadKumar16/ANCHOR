//
//  Color+Theme.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//

import SwiftUI

// MARK: - Color Extensions
extension Color {
    // MARK: - App Colors
    static let anchorPrimary = Color(red: 0.0, green: 0.48, blue: 1.0) // Default blue
    static let anchorAccent = Color(red: 0.0, green: 0.79, blue: 0.63) // Teal accent
    
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // MARK: - Utility
    func toHex() -> String? {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return nil
        }
        
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a: Float = 1.0
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if a != 1.0 {
            return String(format: "%02lX%02lX%02lX%02lX",
                         lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX",
                         lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}

// MARK: - View Modifiers
extension View {
    func cardStyle(backgroundColor: Color = ANCHORDesign.Colors.backgroundCard,
                  cornerRadius: CGFloat = 12,
                  shadowRadius: CGFloat = 5,
                  padding: CGFloat = 16) -> some View {
        self.padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(backgroundColor)
                    .shadow(color: Color.black.opacity(0.1), radius: shadowRadius, x: 0, y: 2)
            )
    }
    
    func primaryButtonStyle(isFullWidth: Bool = true, isDisabled: Bool = false) -> some View {
        self.buttonStyle(PrimaryButtonStyle(isFullWidth: isFullWidth, isDisabled: isDisabled))
    }
    
    func secondaryButtonStyle(isFullWidth: Bool = true, isDisabled: Bool = false) -> some View {
        self.buttonStyle(SecondaryButtonStyle(isFullWidth: isFullWidth, isDisabled: isDisabled))
    }
    
    func withCardAnimation<Result: Equatable>(_ animation: Animation = .easeInOut(duration: 0.3), _ body: @escaping () -> Result) -> some View {
        return self.animation(animation, value: body())
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    var isFullWidth: Bool = true
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding()
            .background(ANCHORDesign.Colors.primary.opacity(isDisabled ? 0.5 : 1.0))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .disabled(isDisabled)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var isFullWidth: Bool = true
    var isDisabled: Bool = false
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(ANCHORDesign.Colors.primary)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ANCHORDesign.Colors.primary, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
            .disabled(isDisabled)
    }
}

// MARK: - Text Extensions
extension Text {
    func largeTitleStyle() -> some View {
        self
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(ANCHORDesign.Colors.textPrimary)
    }
    
    func titleStyle() -> some View {
        self
            .font(.title)
            .fontWeight(.semibold)
            .foregroundColor(ANCHORDesign.Colors.textPrimary)
    }
    
    func headlineStyle() -> some View {
        self
            .font(.headline)
            .foregroundColor(ANCHORDesign.Colors.textPrimary)
    }
    
    func subheadlineStyle() -> some View {
        self
            .font(.subheadline)
            .foregroundColor(ANCHORDesign.Colors.textSecondary)
    }
    
    func captionStyle() -> some View {
        self
            .font(.caption)
            .foregroundColor(ANCHORDesign.Colors.textSecondary)
    }
    
    func errorStyle() -> some View {
        self
            .font(.caption)
            .foregroundColor(ANCHORDesign.Colors.error)
    }
    
    func successStyle() -> some View {
        self
            .font(.caption)
            .foregroundColor(ANCHORDesign.Colors.success)
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
                    .background(ANCHORDesign.Colors.primary)
                
                Text("Secondary")
                    .padding()
                    .background(ANCHORDesign.Colors.secondary)
                
                Text("Background")
                    .padding()
                    .background(ANCHORDesign.Colors.background)
                
                Text("Card Background")
                    .padding()
                    .background(ANCHORDesign.Colors.backgroundCard)
            }
            .previewDisplayName("Light Mode")
            .preferredColorScheme(.light)
            
            // Dark Mode
            VStack(spacing: 20) {
                Text("Primary")
                    .padding()
                    .background(ANCHORDesign.Colors.primary)
                
                Text("Secondary")
                    .padding()
                    .background(ANCHORDesign.Colors.secondary)
                
                Text("Background")
                    .padding()
                    .background(ANCHORDesign.Colors.background)
                
                Text("Card Background")
                    .padding()
                    .background(ANCHORDesign.Colors.backgroundCard)
            }
            .previewDisplayName("Dark Mode")
            .preferredColorScheme(.dark)
        }
        .padding()
    }
}
