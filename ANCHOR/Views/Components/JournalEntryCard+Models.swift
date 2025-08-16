//
//  JournalEntryCard+Models.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

// MARK: - Supporting Types

extension JournalEntryCard {
    enum CardStyle {
        case minimal
        case standard
        case detailed
        case compact
        case featured
        
        var backgroundColor: Color {
            switch self {
            case .minimal: return ANCHORDesign.Colors.backgroundCard.opacity(0.5)
            case .standard: return ANCHORDesign.Colors.backgroundCard
            case .detailed: return ANCHORDesign.Colors.backgroundCard
            case .compact: return ANCHORDesign.Colors.backgroundSecondary
            case .featured: return ANCHORDesign.Colors.backgroundCard
            }
        }
        
        var shadow: ANCHORDesign.Shadow {
            switch self {
            case .minimal: return ANCHORDesign.Shadow.none
            case .standard: return ANCHORDesign.Shadow.medium
            case .detailed: return ANCHORDesign.Shadow.large
            case .compact: return ANCHORDesign.Shadow.small
            case .featured: return ANCHORDesign.Shadow.large
            }
        }
        
        var tagStyle: TagView.TagStyle {
            switch self {
            case .minimal: return .minimal
            case .standard: return .standard
            case .detailed: return .gradient
            case .compact: return .minimal
            case .featured: return .gradient
            }
        }
    }
    
    enum CardSize {
        case small
        case medium
        case large
        
        var padding: CGFloat {
            switch self {
            case .small: return ANCHORDesign.Spacing.sm
            case .medium: return ANCHORDesign.Spacing.md
            case .large: return ANCHORDesign.Spacing.lg
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return ANCHORDesign.CornerRadius.medium
            case .medium: return ANCHORDesign.CornerRadius.large
            case .large: return ANCHORDesign.CornerRadius.extraLarge
            }
        }
        
        var contentSpacing: CGFloat {
            switch self {
            case .small: return ANCHORDesign.Spacing.xs
            case .medium: return ANCHORDesign.Spacing.sm
            case .large: return ANCHORDesign.Spacing.md
            }
        }
        
        var titleStyle: ANCHORDesign.Typography.Style {
            switch self {
            case .small: return ANCHORDesign.Typography.Style.callout
            case .medium: return ANCHORDesign.Typography.Style.bodyBold
            case .large: return ANCHORDesign.Typography.Style.title3
            }
        }
        
        var bodyStyle: ANCHORDesign.Typography.Style {
            switch self {
            case .small: return ANCHORDesign.Typography.Style.caption1
            case .medium: return ANCHORDesign.Typography.Style.callout
            case .large: return ANCHORDesign.Typography.Style.body
            }
        }
        
        var dateStyle: ANCHORDesign.Typography.Style {
            switch self {
            case .small: return ANCHORDesign.Typography.Style.caption2
            case .medium: return ANCHORDesign.Typography.Style.caption1
            case .large: return ANCHORDesign.Typography.Style.callout
            }
        }
        
        var timeStyle: ANCHORDesign.Typography.Style {
            switch self {
            case .small: return ANCHORDesign.Typography.Style.caption2
            case .medium: return ANCHORDesign.Typography.Style.caption2
            case .large: return ANCHORDesign.Typography.Style.caption1
            }
        }
        
        var tagSize: TagView.TagSize {
            switch self {
            case .small: return .small
            case .medium: return .medium
            case .large: return .large
            }
        }
    }
    
    enum DateDisplayFormat {
        case dateOnly
        case timeOnly
        case dateAndTime
        case relative
    }
    
    enum InteractionStyle {
        case standard
        case minimal
        case prominent
        
        var chevronIcon: String {
            switch self {
            case .standard: return "chevron.right"
            case .minimal: return "chevron.right"
            case .prominent: return "arrow.right.circle.fill"
            }
        }
    }
    
    struct ContextMenuAction: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let isEnabled: Bool
        let isDivider: Bool
        let handler: () -> Void
        
        init(title: String, icon: String, isEnabled: Bool = true, handler: @escaping () -> Void) {
            self.init(title: title, icon: icon, isEnabled: isEnabled, isDivider: false, handler: handler)
        }

        private init(title: String, icon: String, isEnabled: Bool, isDivider: Bool, handler: @escaping () -> Void) {
            self.title = title
            self.icon = icon
            self.isEnabled = isEnabled
            self.isDivider = isDivider
            self.handler = handler
        }
        
        static func divider() -> ContextMenuAction {
            return ContextMenuAction(title: "", icon: "", isEnabled: false, isDivider: true, handler: {})
        }
    }
    
}

// MARK: - Tag View Component
struct TagView: View {
    let text: String
    let style: TagStyle
    let size: TagSize
    
    var body: some View {
        Text(text)
            .font(.system(size: size.fontSize, weight: size.fontWeight))
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, size.verticalPadding)
            .background(style.background)
            .foregroundColor(style.foregroundColor)
            .cornerRadius(size.cornerRadius)
    }
    
    enum TagStyle {
        case minimal
        case standard
        case gradient
        
        var background: AnyView {
            switch self {
            case .minimal:
                return AnyView(ANCHORDesign.Colors.textTertiary.opacity(0.1))
            case .standard:
                return AnyView(ANCHORDesign.Colors.primary.opacity(0.1))
            case .gradient:
                return AnyView(
                    LinearGradient(
                        colors: [ANCHORDesign.Colors.primary.opacity(0.1), ANCHORDesign.Colors.accent.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .minimal: return ANCHORDesign.Colors.textTertiary
            case .standard: return ANCHORDesign.Colors.primary
            case .gradient: return ANCHORDesign.Colors.primary
            }
        }
    }
    
    enum TagSize {
        case small
        case medium
        case large
        
        var fontSize: CGFloat {
            switch self {
            case .small: return 9
            case .medium: return 10
            case .large: return 11
            }
        }
        
        var fontWeight: Font.Weight {
            switch self {
            case .small: return .medium
            case .medium: return .medium
            case .large: return .semibold
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 6
            case .medium: return 8
            case .large: return 10
            }
        }
        
        var verticalPadding: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return 4
            case .large: return 6
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return ANCHORDesign.CornerRadius.small
            case .medium: return ANCHORDesign.CornerRadius.small
            case .large: return ANCHORDesign.CornerRadius.medium
            }
        }
    }
}

// MARK: - Accessibility Extension
extension ANCHORMoodIcon.MoodType {
    var accessibilityLabel: String {
        switch self {
        case .veryHappy: return "very happy"
        case .happy: return "happy"
        case .neutral: return "neutral"
        case .sad: return "sad"
        case .verySad: return "very sad"
        }
    }
}
