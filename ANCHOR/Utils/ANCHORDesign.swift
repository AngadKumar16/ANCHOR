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
        public static let tertiary = Color.purple
        
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
        
        // UI Element Colors
        public static let border = Color.gray.opacity(0.2)
        public static let shadow = Color.black.opacity(0.1)
        
        // Semantic Colors
        public static let success = Color(hex: "2ECC71")  // Vibrant green
        public static let warning = Color(hex: "F39C12")  // Warm orange
        public static let error = Color(hex: "E74C3C")    // Bright red
        public static let info = Color(hex: "3498DB")     // Friendly blue
        
        // Mood Colors - Gradient from sad to happy
        public static let moodVerySad = Color(hex: "8E44AD")  // Deep purple
        public static let moodSad = Color(hex: "3498DB")      // Blue
        public static let moodNeutral = Color(hex: "2ECC71")  // Green
        public static let moodHappy = Color(hex: "F1C40F")    // Yellow
        public static let moodVeryHappy = Color(hex: "E67E22") // Orange
        public static let moodAnxious = Color(hex: "E74C3C")  // Red
        public static let moodAngry = Color(hex: "C0392B")    // Dark red
        
        // Additional UI Colors
        public static let highlight = Color(hex: "E3F2FD")    // Light blue for selection
        public static let shimmer = Color.white.opacity(0.6)   // For shimmer effects
        public static let overlay = Color.black.opacity(0.4)  // For overlays
        
        // Social Media Colors (if needed)
        public static let facebook = Color(hex: "3B5998")
        public static let twitter = Color(hex: "1DA1F2")
        public static let instagram = Color(hex: "E1306C")
        
        // Gradients
        public static var primaryGradient: LinearGradient {
            LinearGradient(
                gradient: Gradient(colors: [primary, primaryLight]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        public static var moodGradient: LinearGradient {
            LinearGradient(
                gradient: Gradient(colors: [moodVerySad, moodSad, moodNeutral, moodHappy, moodVeryHappy]),
                startPoint: .leading,
                endPoint: .trailing
            )
        }
        
        public static var successGradient: LinearGradient {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "2ECC71"), Color(hex: "27AE60")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        public static var errorGradient: LinearGradient {
            LinearGradient(
                gradient: Gradient(colors: [Color(hex: "E74C3C"), Color(hex: "C0392B")]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        
        public static var accentGradient: LinearGradient {
            LinearGradient(
                gradient: Gradient(colors: [accent, accentLight]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
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
    let gradient: Gradient?
    let showBorder: Bool
    @State private var isPressed = false
    
    public init(
        padding: CGFloat = ANCHORDesign.Spacing.md,
        cornerRadius: CGFloat = ANCHORDesign.CornerRadius.medium,
        shadowStyle: ANCHORDesign.Shadow = ANCHORDesign.Shadow.small,
        backgroundColor: Color = ANCHORDesign.Colors.backgroundCard,
        gradient: Gradient? = nil,
        showBorder: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.shadowStyle = shadowStyle
        self.backgroundColor = backgroundColor
        self.gradient = gradient
        self.showBorder = showBorder
    }
    
    public var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    if let gradient = gradient {
                        LinearGradient(
                            gradient: gradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        backgroundColor
                    }
                }
                .cornerRadius(cornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(showBorder ? ANCHORDesign.Colors.primary.opacity(0.2) : .clear, lineWidth: 1)
                )
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(
                color: shadowStyle.color.opacity(isPressed ? 0.3 : 1.0),
                radius: isPressed ? shadowStyle.radius * 0.8 : shadowStyle.radius,
                x: shadowStyle.x,
                y: isPressed ? shadowStyle.y * 0.5 : shadowStyle.y
            )
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .onTapGesture {
                // Haptic feedback on tap
                let impactMed = UIImpactFeedbackGenerator(style: .medium)
                impactMed.impactOccurred()
            }
            .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
                withAnimation(.easeInOut(duration: 0.2)) {
                    isPressed = pressing
                }
            }, perform: {})
    }
}

// Extension for easy gradient creation
extension ANCHORCard where Content: View {
    public static func gradient(
        _ gradient: Gradient,
        padding: CGFloat = ANCHORDesign.Spacing.md,
        cornerRadius: CGFloat = ANCHORDesign.CornerRadius.medium,
        shadowStyle: ANCHORDesign.Shadow = ANCHORDesign.Shadow.medium,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ANCHORCard(
            padding: padding,
            cornerRadius: cornerRadius,
            shadowStyle: shadowStyle,
            gradient: gradient,
            showBorder: false,
            content: content
        )
    }
}
