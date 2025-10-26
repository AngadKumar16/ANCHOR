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
public typealias ANCHORGradientBackground = GradientBackground

/// ANCHOR Design System
/// Centralized design tokens for consistent UI across the app
public struct ANCHORDesign {
    
    // MARK: - Colors
    public struct Colors {
        // Primary Colors
        public static let primary = Color.anchorPrimary
        public static let primaryLight = Color.anchorPrimary.opacity(0.7)
        public static let accent = Color.anchorAccent
        public static let accentLight = Color.anchorAccent.opacity(0.7)
        public static let secondary = Color.blue
        
        // Background Colors
        public static let background = Color(UIColor.systemBackground)
        public static let backgroundPrimary = Color(UIColor.systemBackground)
        public static let backgroundSecondary = Color(UIColor.secondarySystemBackground)
        public static let backgroundTertiary = Color(UIColor.tertiarySystemBackground)
        public static let backgroundCard = Color(UIColor.secondarySystemBackground)
        
        // Text Colors
        public static let textPrimary = Color(UIColor.label)
        public static let textSecondary = Color(UIColor.secondaryLabel)
        public static let textTertiary = Color(UIColor.tertiaryLabel)
        
        // Semantic Colors
        public static let success = Color.green
        public static let warning = Color.orange
        public static let error = Color.red
        public static let info = Color.blue
        
        // Mood Colors
        public static let moodVeryHappy = Color.yellow
        public static let moodHappy = Color.yellow.opacity(0.8)
        public static let moodCalm = Color.blue
        public static let moodSad = Color.indigo
        public static let moodAnxious = Color.orange
        public static let moodAngry = Color.red
        public static let moodNeutral = Color.gray
    }
    
    // MARK: - Typography
    public struct Typography {
        public enum Style {
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
            
            public var font: Font {
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
    public struct Spacing {
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    public struct CornerRadius {
        public static let small: CGFloat = 4
        public static let medium: CGFloat = 8
        public static let large: CGFloat = 12
        public static let extraLarge: CGFloat = 16
        public static let round: CGFloat = 999
    }
    
    // MARK: - Shadows
    public struct Shadow {
        public let color: Color
        public let radius: CGFloat
        public let x: CGFloat
        public let y: CGFloat
        
        public static let none = Shadow(color: .clear, radius: 0, x: 0, y: 0)
        public static let small = Shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        public static let medium = Shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
        public static let large = Shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - View Extensions
extension View {
    public func anchorTextStyle(_ style: ANCHORDesign.Typography.Style) -> some View {
        self.font(style.font)
    }
}

// MARK: - ANCHORCard Component
public struct ANCHORCard<Content: View>: View {
    let content: Content
    let padding: CGFloat
    let cornerRadius: CGFloat
    let shadowStyle: ANCHORDesign.Shadow
    let backgroundColor: Color
    
    public init(
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
    
    public var body: some View {
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
