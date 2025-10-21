//
//  RecoveryTipCard.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

// Add this at the top of the file or in a separate ButtonStyles.swift file
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut, value: configuration.isPressed)
    }
}

struct RecoveryTipCard: View {
    // MARK: - Core Properties
    let icon: String
    let title: String
    let description: String
    let color: Color
    
    // MARK: - Customization Properties
    let style: CardStyle
    let size: CardSize
    let layout: Layout
    let showIcon: Bool
    let iconStyle: IconStyle
    let showChevron: Bool
    let showBadge: Bool
    let badgeText: String?
    let badgeColor: Color?
    let priority: Priority
    let category: String?
    let showCategory: Bool
    let maxDescriptionLines: Int?
    let customBackground: AnyView?
    let customPadding: EdgeInsets?
    let customCornerRadius: CGFloat?
    let customShadow: ANCHORDesign.Shadow?
    let onTap: (() -> Void)?
    let onLongPress: (() -> Void)?
    
    // MARK: - Animation Properties
    let animateOnAppear: Bool
    let hoverEffect: Bool
    let scaleOnPress: Bool
    let hapticFeedback: Bool
    
    // MARK: - Accessibility Properties
    let accessibilityLabel: String?
    let accessibilityHint: String?
    let accessibilityValue: String?
    
    // MARK: - State
    @State private var hasAppeared = false
    @State private var isPressed = false
    @State private var isHovered = false
    
    // MARK: - Initializers
    init(
        icon: String,
        title: String,
        description: String,
        color: Color,
        style: CardStyle = .standard,
        size: CardSize = .medium,
        layout: Layout = .horizontal,
        showIcon: Bool = true,
        iconStyle: IconStyle = .filled,
        showChevron: Bool = false,
        showBadge: Bool = false,
        badgeText: String? = nil,
        badgeColor: Color? = nil,
        priority: Priority = .normal,
        category: String? = nil,
        showCategory: Bool = false,
        maxDescriptionLines: Int? = 2,
        customBackground: AnyView? = nil,
        customPadding: EdgeInsets? = nil,
        customCornerRadius: CGFloat? = nil,
        customShadow: ANCHORDesign.Shadow? = nil,
        animateOnAppear: Bool = false,
        hoverEffect: Bool = true,
        scaleOnPress: Bool = true,
        hapticFeedback: Bool = false,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        accessibilityValue: String? = nil,
        onTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.color = color
        self.style = style
        self.size = size
        self.layout = layout
        self.showIcon = showIcon
        self.iconStyle = iconStyle
        self.showChevron = showChevron
        self.showBadge = showBadge
        self.badgeText = badgeText
        self.badgeColor = badgeColor
        self.priority = priority
        self.category = category
        self.showCategory = showCategory
        self.maxDescriptionLines = maxDescriptionLines
        self.customBackground = customBackground
        self.customPadding = customPadding
        self.customCornerRadius = customCornerRadius
        self.customShadow = customShadow
        self.animateOnAppear = animateOnAppear
        self.hoverEffect = hoverEffect
        self.scaleOnPress = scaleOnPress
        self.hapticFeedback = hapticFeedback
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.accessibilityValue = accessibilityValue
        self.onTap = onTap
        self.onLongPress = onLongPress
    }
    
    // MARK: - Computed Properties
    private var cardPadding: EdgeInsets {
        customPadding ?? EdgeInsets(
            top: size.padding,
            leading: size.padding,
            bottom: size.padding,
            trailing: size.padding
        )
    }
    
    private var cardCornerRadius: CGFloat {
        customCornerRadius ?? size.cornerRadius
    }
    
    private var cardShadow: ANCHORDesign.Shadow {
        customShadow ?? style.shadow
    }
    
    private var iconSize: CGFloat {
        switch size {
        case .small: return 14
        case .medium: return 18
        case .large: return 22
        case .extraLarge: return 26
        }
    }
    
    private var iconContainerSize: CGFloat {
        switch size {
        case .small: return 32
        case .medium: return 40
        case .large: return 48
        case .extraLarge: return 56
        }
    }
    
    private var priorityColor: Color {
        switch priority {
        case .low: return ANCHORDesign.Colors.textTertiary
        case .normal: return color
        case .high: return ANCHORDesign.Colors.warning
        case .urgent: return ANCHORDesign.Colors.error
        }
    }
    
    // MARK: - Computed Properties for View Configuration
    
    private var computedOpacity: Double {
        hasAppeared || !animateOnAppear ? 1.0 : 0.0
    }
    
    private var computedAccessibilityLabel: String {
        accessibilityLabel ?? "\(title). \(description)"
    }
    
    private var computedAccessibilityHint: String? {
        accessibilityHint ?? (onTap != nil ? "Double tap to view tip details" : nil)
    }
    
    private var computedAccessibilityTraits: AccessibilityTraits {
        onTap != nil ? .isButton : .isStaticText
    }
    
    // MARK: - Main Body
    
    var body: some View {
        mainContentWrapper
            .scaleEffect(getScaleEffect())
            .opacity(computedOpacity)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPressed)
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
    private var mainContentWrapper: some View {
        if hasTapAction {
            tapableCard
        } else if customBackground != nil {
            mainContentWithCustomBackground
        } else {
            mainContentWithDefaultBackground
        }
    }
    
    @ViewBuilder
    private var tapableCard: some View {
        Button(action: handleTap) {
            cardContent
                .scaleEffect(scaleOnPress && isPressed ? 0.98 : 1.0)
                .opacity(scaleOnPress && isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(ScaleButtonStyle())
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
    
    // MARK: - Helper Properties
    
    private var hasTapAction: Bool {
        onTap != nil || onLongPress != nil
    }
    
    // MARK: - View Builders
    
    
    private func handleAppear() {
        if animateOnAppear {
            withAnimation(.easeOut(duration: 0.6).delay(Double.random(in: 0...0.3))) {
                hasAppeared = true
            }
        } else {
            hasAppeared = true
        }
    }
    
    // MARK: - Card Content Components
    
    // MARK: - Background Layer
    @ViewBuilder
    private var backgroundLayer: some View {
        // Background layer is intentionally empty as backgrounds are handled by main content views
        Color.clear
    }
    
    // MARK: - Card Content
    @ViewBuilder
    private var cardContent: some View {
        if let customBackground = customBackground {
            mainContent
                .padding(cardPadding)
                .background(customBackground)
        } else {
            ZStack {
                backgroundLayer
                mainContentWrapper
                overlayViews
            }
        }
    }
    
    @ViewBuilder
    private var mainContentWithCustomBackground: some View {
        mainContent
            .padding(cardPadding)
            .background(customBackground)
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
    private var backgroundContent: some View {
        // Background layer is now handled directly in cardContent
        EmptyView()
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
    @ViewBuilder
    private var mainContent: some View {
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
    private func getScaleEffect() -> CGFloat {
        if isPressed && scaleOnPress {
            return 0.98
        } else if isHovered && hoverEffect {
            return 1.02
        } else if hasAppeared || !animateOnAppear {
            return 1.0
        } else {
            return 0.95
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
