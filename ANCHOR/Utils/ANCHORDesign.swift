//
//  ANCHORDesign.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/14/25.
//

import SwiftUI

// MARK: - Type Aliases

/// Typealias for backward compatibility with existing code
/// Use `GradientBackground` directly in new code
typealias ANCHORGradientBackground = GradientBackground

/// ANCHOR Design System
/// Centralized design tokens for consistent UI across the app
struct ANCHORDesign {
    
    // MARK: - Colors
    struct Colors {
        // Primary Colors
        static let primary = Color.anchorPrimary
        static let primaryLight = Color.anchorPrimary.opacity(0.7)
        static let accent = Color.anchorAccent
        static let accentLight = Color.anchorAccent.opacity(0.7)
        static let secondary = Color.blue
        
        // Background Colors
        static let background = Color(UIColor.systemBackground)
        static let backgroundPrimary = Color(UIColor.systemBackground)
        static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
        static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)
        static let backgroundCard = Color(UIColor.secondarySystemBackground)
        
        // Text Colors
        static let textPrimary = Color(UIColor.label)
        static let textSecondary = Color(UIColor.secondaryLabel)
        static let textTertiary = Color(UIColor.tertiaryLabel)
        
        // Semantic Colors
        static let success = Color.green
        static let warning = Color.orange
        static let error = Color.red
        static let info = Color.blue
        
        // Mood Colors
        static let moodVeryHappy = Color.yellow
        static let moodHappy = Color.yellow.opacity(0.8)
        static let moodCalm = Color.blue
        static let moodSad = Color.indigo
        static let moodAnxious = Color.orange
        static let moodAngry = Color.red
        static let moodNeutral = Color.gray
    }
    
    // MARK: - Typography
    struct Typography {
        enum Style {
            case largeTitle
            case title1
            case title2
            case title3
            case headline
            case body
            case bodyBold
            case callout
            case subheadline
            case footnote
            case caption1
            case caption2
            
            var font: Font {
                switch self {
                case .largeTitle: return .largeTitle
                case .title1: return .title
                case .title2: return .title2
                case .title3: return .title3
                case .headline: return .headline
                case .body: return .body
                case .bodyBold: return .body.bold()
                case .callout: return .callout
                case .subheadline: return .subheadline
                case .footnote: return .footnote
                case .caption1: return .caption
                case .caption2: return .caption2
                }
            }
        }
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let extraLarge: CGFloat = 16
        static let round: CGFloat = 999
    }
    
    // MARK: - Shadows
    struct Shadow {
        let color: Color
        let radius: CGFloat
        let x: CGFloat
        let y: CGFloat
        
        static let none = Shadow(color: .clear, radius: 0, x: 0, y: 0)
        static let small = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        static let medium = Shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        static let large = Shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - View Extensions
extension View {
    func anchorTextStyle(_ style: ANCHORDesign.Typography.Style) -> some View {
        self.font(style.font)
    }
}

// MARK: - ANCHORCard Component
struct ANCHORCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadowStyle: ANCHORDesign.Shadow
    let backgroundColor: Color
    
    init(
        padding: CGFloat = ANCHORDesign.Spacing.md,
        cornerRadius: CGFloat = ANCHORDesign.CornerRadius.medium,
        shadowStyle: ANCHORDesign.Shadow = ANCHORDesign.Shadow.small,
        backgroundColor: Color = ANCHORDesign.Colors.backgroundCard,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowStyle = shadowStyle
        self.backgroundColor = backgroundColor
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadowStyle.color,
                radius: shadowStyle.radius,
                x: shadowStyle.x,
                y: shadowStyle.y
            )
    }
}
