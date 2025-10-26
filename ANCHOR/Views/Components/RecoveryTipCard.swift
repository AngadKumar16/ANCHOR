//
//  RecoveryTipCard.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI
import ButtonStyles // Import the ButtonStyles module

// ... (rest of the code remains the same)

// MARK: - Main Body

var body: some View {
    mainContentWrapper
        .opacity(computedOpacity)
        .animation(.easeOut(duration: 0.6), value: hasAppeared)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onAppear(perform: handleAppear)
        .onHover { hovering in
            if hoverEffect {
                isHovered = hovering
            }
        }
        .accessibilityLabel(computedAccessibilityLabel)
        .accessibilityHint(computedAccessibilityHint ?? "")
        .accessibilityValue(accessibilityValue ?? "")
        .accessibilityAddTraits(computedAccessibilityTraits)
}

// MARK: - Content Wrappers
@ViewBuilder
private var cardContent: some View {
    if customBackground != nil {
        mainContentWithCustomBackground
    } else {
        mainContentWithDefaultBackground
    }
}

@ViewBuilder
private var mainContentWrapper: some View {
    if hasTapAction {
        tapableCard
    } else if customBackground != nil {
        mainContentWithCustomBackground
    } else {
        mainContentWithDefaultBackground
    }
}

// MARK: - Card Content
@ViewBuilder
private var mainContentWithCustomBackground: some View {
    mainContent
        .padding(cardPadding)
        .background(customBackground)
        .cornerRadius(cardCornerRadius)
}

@ViewBuilder
private var mainContentWithDefaultBackground: some View {
    mainContent
        .padding(cardPadding)
        .background(cardBackground)
        .cornerRadius(cardCornerRadius)
        .shadow(
            color: cardShadow.color,
            radius: cardShadow.radius,
            x: cardShadow.x,
            y: cardShadow.y
        )
}

@ViewBuilder
private var tapableCard: some View {
    Button(action: handleTap) {
        cardContent
            .scaleEffect(scaleOnPress && isPressed ? 0.98 : 1.0)
            .opacity(scaleOnPress && isPressed ? 0.9 : 1.0)
    }
    .buttonStyle(ScaleButtonStyle()) // Use the imported ScaleButtonStyle
    .onLongPressGesture(minimumDuration: 0.3, pressing: { pressing in
        if hapticFeedback && pressing {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
        }
        isPressed = pressing
    }, perform: {
        onLongPress?()
    })
}

    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        ZStack {
            backgroundLayer
            content
            overlayViews
        }
    }

    @ViewBuilder
    private var content: some View {
        switch layout {
        case .horizontal:
            horizontalLayout
        case .vertical:
            verticalLayout
        case .compact:
            compactLayout
        case .featured:
            featuredLayout
        }
    }
    
    // MARK: - Helper Properties
    
    private var hasTapAction: Bool {
        onTap != nil || onLongPress != nil
    }
    
    // MARK: - View Builders
    
    // MARK: - Background Layer
    @ViewBuilder
    private var backgroundLayer: some View {
        // Background layer is intentionally empty as backgrounds are handled by main content views
        Color.clear
    }
    
    @ViewBuilder
    private var overlayViews: some View {
        Group {
            if showBadge {
                badgeView
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            }
            
            if priority != .normal {
                priorityIndicator
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
    
    // MARK: - Layout Selection
    
    // MARK: - Horizontal Layout
    @ViewBuilder
    private var horizontalLayout: some View {
        HStack(spacing: size.contentSpacing) {
            horizontalLeadingContent
            Spacer()
            if showChevron {
                chevronView
            }
        }
    }
    
    @ViewBuilder
    private var horizontalLeadingContent: some View {
        if showIcon {
            iconView
        }
        
        horizontalTextContent
    }
    
    @ViewBuilder
    private var horizontalTextContent: some View {
        VStack(alignment: .leading, spacing: size.textSpacing) {
            if showCategory, let category = category {
                categoryView(category)
            }
            
            Text(title)
                .anchorTextStyle(size.titleStyle)
                .foregroundColor(ANCHORDesign.Colors.textPrimary)
                .multilineTextAlignment(.leading)
            
            Text(description)
                .anchorTextStyle(size.descriptionStyle)
                .foregroundColor(ANCHORDesign.Colors.textSecondary)
                .lineLimit(maxDescriptionLines)
                .multilineTextAlignment(.leading)
        }
    }
    
    // MARK: - Vertical Layout
    @ViewBuilder
    private var verticalLayout: some View {
        VStack(spacing: size.contentSpacing) {
            verticalTopContent
            verticalTextContent
            
            if showChevron {
                chevronView
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var verticalTopContent: some View {
        if showIcon {
            iconView
        }
    }
    
    @ViewBuilder
    private var verticalTextContent: some View {
        VStack(spacing: size.textSpacing) {
            if showCategory, let category = category {
                categoryView(category)
            }
            
            Text(title)
                .anchorTextStyle(size.titleStyle)
                .foregroundColor(ANCHORDesign.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            Text(description)
                .anchorTextStyle(size.descriptionStyle)
                .foregroundColor(ANCHORDesign.Colors.textSecondary)
                .lineLimit(maxDescriptionLines)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Compact Layout
    @ViewBuilder
    private var compactLayout: some View {
        HStack(spacing: size.contentSpacing) {
            compactLeadingContent
            Spacer()
            if showChevron {
                chevronView
            }
        }
    }
    
    @ViewBuilder
    private var compactLeadingContent: some View {
        if showIcon {
            iconView
        }
        
        compactTextContent
    }
    
    @ViewBuilder
    private var compactTextContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .anchorTextStyle(size.titleStyle)
                .foregroundColor(ANCHORDesign.Colors.textPrimary)
                .lineLimit(1)
            
            Text(description)
                .anchorTextStyle(size.compactDescriptionStyle)
                .foregroundColor(ANCHORDesign.Colors.textSecondary)
                .lineLimit(1)
        }
    }
    
    // MARK: - Featured Layout
    @ViewBuilder
    private var featuredLayout: some View {
        VStack(spacing: size.contentSpacing) {
            featuredTopContent
            featuredTextContent
            
            if showChevron {
                chevronView
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var featuredTopContent: some View {
        if showIcon {
            iconView
        }
    }
    
    @ViewBuilder
    private var featuredTextContent: some View {
        VStack(spacing: size.textSpacing) {
            if showCategory, let category = category {
                categoryView(category)
            }
            
            Text(title)
                .anchorTextStyle(size.featuredTitleStyle)
                .foregroundColor(priorityColor)
                .multilineTextAlignment(.center)
            
            Text(description)
                .anchorTextStyle(size.descriptionStyle)
                .foregroundColor(ANCHORDesign.Colors.textSecondary)
                .lineLimit(maxDescriptionLines)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var iconView: some View {
        ZStack {
            switch iconStyle {
            case .filled:
                Circle()
                    .fill(priorityColor.opacity(0.2))
                    .frame(width: iconContainerSize, height: iconContainerSize)
                
            case .outlined:
                Circle()
                    .stroke(priorityColor, lineWidth: 1.5)
                    .frame(width: iconContainerSize, height: iconContainerSize)
                
            case .minimal:
                EmptyView()
            }
            
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(priorityColor)
        }
    }
    
    @ViewBuilder
    private var chevronView: some View {
        Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundColor(ANCHORDesign.Colors.textTertiary)
    }
    
    @ViewBuilder
    private var badgeView: some View {
        if let badgeText = badgeText {
            Text(badgeText)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(badgeColor ?? priorityColor)
                .cornerRadius(8)
                .offset(x: 8, y: -8)
        }
    }
    
    @ViewBuilder
    private var priorityIndicator: some View {
        Circle()
            .fill(priorityColor)
            .frame(width: 8, height: 8)
            .offset(x: 8, y: 8)
    }
    
    @ViewBuilder
    private func categoryView(_ category: String) -> some View {
        Text(category.uppercased())
            .font(.caption2)
            .fontWeight(.semibold)
            .foregroundColor(priorityColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(priorityColor.opacity(0.1))
            .cornerRadius(4)
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        Group {
            switch style {
            case .standard:
                ANCHORDesign.Colors.backgroundCard
            case .elevated:
                ANCHORDesign.Colors.backgroundCard
            case .outlined:
                ANCHORDesign.Colors.backgroundCard
                    .overlay(
                        RoundedRectangle(cornerRadius: cardCornerRadius)
                            .stroke(priorityColor.opacity(0.3), lineWidth: 1)
                    )
            case .gradient:
                LinearGradient(
                    colors: [priorityColor.opacity(0.1), priorityColor.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .glassmorphism:
                priorityColor.opacity(0.05)
                    .background(.ultraThinMaterial)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleAppear() {
        if animateOnAppear {
            withAnimation(.easeOut(duration: 0.6).delay(Double.random(in: 0...0.3))) {
                hasAppeared = true
            }
        } else {
            hasAppeared = true
        }
    }
    
    private func handleTap() {
        if hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        if scaleOnPress {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = false
                }
            }
        }
        
        onTap?()
    }
    
    private func handleLongPress() {
        if hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        }
        
        onLongPress?()
    }
}

// MARK: - Supporting Types
extension RecoveryTipCard {
    enum CardStyle {
        case standard
        case elevated
        case outlined
        case gradient
        case glassmorphism
        
        var shadow: ANCHORDesign.Shadow {
            switch self {
            case .standard: return ANCHORDesign.Shadow.small
            case .elevated: return ANCHORDesign.Shadow.medium
            case .outlined: return ANCHORDesign.Shadow.small
            case .gradient: return ANCHORDesign.Shadow.small
            case .glassmorphism: return ANCHORDesign.Shadow.small
            }
        }
    }
    
    enum CardSize {
        case small
        case medium
        case large
        case extraLarge
        
        var padding: CGFloat {
            switch self {
            case .small: return ANCHORDesign.Spacing.sm
            case .medium: return ANCHORDesign.Spacing.md
            case .large: return ANCHORDesign.Spacing.lg
            case .extraLarge: return ANCHORDesign.Spacing.xl
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: return ANCHORDesign.CornerRadius.small
            case .medium: return ANCHORDesign.CornerRadius.medium
            case .large: return ANCHORDesign.CornerRadius.large
            case .extraLarge: return ANCHORDesign.CornerRadius.extraLarge
            }
        }
        
        var contentSpacing: CGFloat {
            switch self {
            case .small: return ANCHORDesign.Spacing.xs
            case .medium: return ANCHORDesign.Spacing.sm
            case .large: return ANCHORDesign.Spacing.md
            case .extraLarge: return ANCHORDesign.Spacing.lg
            }
        }
        
        var textSpacing: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return ANCHORDesign.Spacing.xs
            case .large: return ANCHORDesign.Spacing.sm
            case .extraLarge: return ANCHORDesign.Spacing.sm
            }
        }
        
        var titleStyle: ANCHORDesign.Typography.Style {
            switch self {
            case .small: return .callout
            case .medium: return .bodyBold
            case .large: return .title3
            case .extraLarge: return .title2
            }
        }
        
        var descriptionStyle: ANCHORDesign.Typography.Style {
            switch self {
            case .small: return .caption1
            case .medium: return .caption1
            case .large: return .callout
            case .extraLarge: return .body
            }
        }
        
        var compactDescriptionStyle: ANCHORDesign.Typography.Style {
            switch self {
            case .small: return .caption2
            case .medium: return .caption1
            case .large: return .caption1
            case .extraLarge: return .callout
            }
        }
        
        var featuredTitleStyle: ANCHORDesign.Typography.Style {
            switch self {
            case .small: return .title3
            case .medium: return .title2
            case .large: return .title1
            case .extraLarge: return .largeTitle
            }
        }
    }
    
    enum Layout {
        case horizontal
        case vertical
        case compact
        case featured
    }
    
    enum IconStyle {
        case filled
        case outlined
        case minimal
    }
    
    enum Priority {
        case low
        case normal
        case high
        case urgent
    }
}

#Preview("Recovery Tip Cards") {
    ScrollView {
        LazyVStack(spacing: 16) {
            // Standard tips
            RecoveryTipCard(
                icon: "lightbulb.fill",
                title: "Daily Reflection",
                description: "Take 5 minutes each morning to set your intentions for the day and reflect on your goals.",
                color: ANCHORDesign.Colors.warning,
                animateOnAppear: true
            )
            
            RecoveryTipCard(
                icon: "heart.fill",
                title: "Practice Gratitude",
                description: "Write down three things you're grateful for today to cultivate a positive mindset.",
                color: ANCHORDesign.Colors.success,
                style: .elevated,
                showBadge: true,
                badgeText: "NEW"
            )
            
            RecoveryTipCard(
                icon: "figure.walk",
                title: "Stay Active",
                description: "A short walk can help clear your mind and boost your mood naturally.",
                color: ANCHORDesign.Colors.primary,
                style: .gradient,
                showChevron: true,
                priority: .high
            )
            
            // Different layouts
            RecoveryTipCard(
                icon: "moon.fill",
                title: "Sleep Hygiene",
                description: "Maintain a consistent sleep schedule for better mental health and recovery.",
                color: ANCHORDesign.Colors.accent,
                style: .elevated,
                layout: .vertical,
                category: "Wellness",
                showCategory: true
            )
            
            RecoveryTipCard(
                icon: "person.2.fill",
                title: "Connect with Support",
                description: "Reach out to friends, family, or support groups when you need help.",
                color: ANCHORDesign.Colors.moodCalm,
                style: .glassmorphism,
                layout: .featured,
                priority: .urgent,
                maxDescriptionLines: 3
            )
            
            // Compact style
            RecoveryTipCard(
                icon: "book.fill",
                title: "Read Recovery Literature",
                description: "Daily reading can provide inspiration and guidance.",
                color: ANCHORDesign.Colors.textSecondary,
                size: .small,
                layout: .compact,
                showChevron: true
            )
        }
        .padding()
    }
}
