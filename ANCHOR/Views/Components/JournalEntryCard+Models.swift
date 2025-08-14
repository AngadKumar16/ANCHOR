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
            case .minimal: return Colors.backgroundCard.opacity(0.5)
            case .standard: return Colors.backgroundCard
            case .detailed: return Colors.backgroundCard
            case .compact: return Colors.backgroundSecondary
            case .featured: return Colors.backgroundCard
            }
        }
        
        var shadow: Shadow {
            switch self {
            case .minimal: return .none
            case .standard: return .medium
            case .detailed: return .large
            case .compact: return .small
            case .featured: return .large
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
            case .small: return Spacing.sm
            case .medium: return Spacing.md
            case .large: return Spacing.lg
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return CornerRadius.medium
            case .medium: return CornerRadius.large
            case .large: return CornerRadius.extraLarge
            }
        }
        
        var contentSpacing: CGFloat {
            switch self {
            case .small: return Spacing.xs
            case .medium: return Spacing.sm
            case .large: return Spacing.md
            }
        }
        
        var titleStyle: Typography.Style {
            switch self {
            case .small: return .callout
            case .medium: return .bodyBold
            case .large: return .title3
            }
        }
        
        var bodyStyle: Typography.Style {
            switch self {
            case .small: return .caption1
            case .medium: return .callout
            case .large: return .body
            }
        }
        
        var dateStyle: Typography.Style {
            switch self {
            case .small: return .caption2
            case .medium: return .caption1
            case .large: return .callout
            }
        }
        
        var timeStyle: Typography.Style {
            switch self {
            case .small: return .caption2
            case .medium: return .caption2
            case .large: return .caption1
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
            self.title = title
            self.icon = icon
            self.isEnabled = isEnabled
            self.isDivider = false
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
                return AnyView(Colors.textTertiary.opacity(0.1))
            case .standard:
                return AnyView(Colors.primary.opacity(0.1))
            case .gradient:
                return AnyView(
                    LinearGradient(
                        colors: [Colors.primary.opacity(0.1), Colors.accent.opacity(0.1)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .minimal: return Colors.textTertiary
            case .standard: return Colors.primary
            case .gradient: return Colors.primary
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
            case .small: return CornerRadius.small
            case .medium: return CornerRadius.small
            case .large: return CornerRadius.medium
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
