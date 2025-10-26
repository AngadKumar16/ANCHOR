//
//  MonthHeaderCard.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

struct MonthHeaderCard: View {
    // MARK: - Core Properties
    let monthYear: String
    let entryCount: Int
    
    // MARK: - Customization Properties
    let style: HeaderStyle
    let size: HeaderSize
    let layout: Layout
    let showIcon: Bool
    let icon: String?
    let iconColor: Color?
    let showEntryCount: Bool
    let showProgress: Bool
    let progressValue: Double?
    let progressColor: Color?
    let showBadge: Bool
    let badgeText: String?
    let badgeColor: Color?
    let showDivider: Bool
    let dividerColor: Color?
    let customBackground: AnyView?
    let customPadding: EdgeInsets?
    let customCornerRadius: CGFloat?
    let customShadow: ANCHORDesign.Shadow?
    let onTap: (() -> Void)?
    
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
        monthYear: String,
        entryCount: Int,
        style: HeaderStyle = .standard,
        size: HeaderSize = .medium,
        layout: Layout = .horizontal,
        showIcon: Bool = false,
        icon: String? = nil,
        iconColor: Color? = nil,
        showEntryCount: Bool = true,
        showProgress: Bool = false,
        progressValue: Double? = nil,
        progressColor: Color? = nil,
        showBadge: Bool = false,
        badgeText: String? = nil,
        badgeColor: Color? = nil,
        showDivider: Bool = false,
        dividerColor: Color? = nil,
        customBackground: AnyView? = nil,
        customPadding: EdgeInsets? = nil,
        customCornerRadius: CGFloat? = nil,
        customShadow: ANCHORDesign.Shadow? = nil,
        animateOnAppear: Bool = false,
        hoverEffect: Bool = false,
        scaleOnPress: Bool = false,
        hapticFeedback: Bool = false,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        accessibilityValue: String? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.monthYear = monthYear
        self.entryCount = entryCount
        self.style = style
        self.size = size
        self.layout = layout
        self.showIcon = showIcon
        self.icon = icon
        self.iconColor = iconColor
        self.showEntryCount = showEntryCount
        self.showProgress = showProgress
        self.progressValue = progressValue
        self.progressColor = progressColor
        self.showBadge = showBadge
        self.badgeText = badgeText
        self.badgeColor = badgeColor
        self.showDivider = showDivider
        self.dividerColor = dividerColor
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
    }
    
    // MARK: - Computed Properties
    private var headerPadding: EdgeInsets {
        customPadding ?? EdgeInsets(
            top: size.padding,
            leading: size.padding,
            bottom: size.padding,
            trailing: size.padding
        )
    }
    
    private var headerCornerRadius: CGFloat {
        customCornerRadius ?? size.cornerRadius
    }
    
    private var headerShadow: ANCHORDesign.Shadow {
        customShadow ?? style.shadow
    }
    
    private var iconSize: CGFloat {
        switch size {
        case .small: return 16
        case .medium: return 20
        case .large: return 24
        case .extraLarge: return 28
        }
    }
    
    private var entryCountText: String {
        if entryCount == 0 {
            return "No entries"
        } else if entryCount == 1 {
            return "1 entry"
        } else {
            return "\(entryCount) entries"
        }
    }
    
    var body: some View {
        mainView
            .modifier(AppearanceModifier(
                hasAppeared: $hasAppeared,
                isPressed: $isPressed,
                isHovered: $isHovered,
                animateOnAppear: animateOnAppear,
                hoverEffect: hoverEffect,
                scaleOnPress: scaleOnPress,
                accessibilityLabel: accessibilityLabel ?? "\(monthYear), \(entryCountText)",
                accessibilityHint: accessibilityHint,
                accessibilityValue: accessibilityValue,
                isInteractive: onTap != nil,
                onAppear: {},
                onHover: { hovering in
                    if hoverEffect {
                        isHovered = hovering
                    }
                }
            ))
    }
    
    @ViewBuilder
    private var mainView: some View {
        if let onTap = onTap {
            Button(action: handleTap) {
                headerContent
            }
            .buttonStyle(PlainButtonStyle())
        } else {
            headerContent
        }
    }
    
    // MARK: - Header Content
    private var headerContent: some View {
        ZStack {
            backgroundContent
            overlays
        }
    }
    
    @ViewBuilder
    private var backgroundContent: some View {
        if let customBg = customBackground {
            mainContent
                .background(customBg)
        } else {
            mainContent
                .padding(headerPadding)
                .background(headerBackground)
                .cornerRadius(headerCornerRadius)
                .shadow(
                    color: headerShadow.color,
                    radius: headerShadow.radius,
                    x: headerShadow.x,
                    y: headerShadow.y
                )
        }
    }
    
    @ViewBuilder
    private var overlays: some View {
        if showBadge {
            badgeView
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }
        
        VStack {
            Spacer()
            if showDivider {
                dividerView
            }
            if showProgress {
                progressView
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        Group {
            switch layout {
            case .horizontal:
                horizontalLayout
            case .vertical:
                verticalLayout
            case .compact:
                compactLayout
            case .centered:
                centeredLayout
            }
        }
    }
    
    @ViewBuilder
    private var horizontalLayout: some View {
        HStack(spacing: size.contentSpacing) {
            if showIcon {
                iconView
            }
            
            VStack(alignment: .leading, spacing: size.textSpacing) {
                Text(monthYear)
                    .anchorTextStyle(size.titleStyle)
                    .foregroundColor(ANCHORDesign.Colors.textPrimary)
                
                if showEntryCount {
                    Text(entryCountText)
                        .anchorTextStyle(size.subtitleStyle)
                        .foregroundColor(ANCHORDesign.Colors.textSecondary)
                }
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var verticalLayout: some View {
        VStack(spacing: size.contentSpacing) {
            if showIcon {
                iconView
            }
            
            VStack(spacing: size.textSpacing) {
                Text(monthYear)
                    .anchorTextStyle(size.titleStyle)
                    .foregroundColor(ANCHORDesign.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                if showEntryCount {
                    Text(entryCountText)
                        .anchorTextStyle(size.subtitleStyle)
                        .foregroundColor(ANCHORDesign.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var compactLayout: some View {
        HStack(spacing: size.contentSpacing) {
            if showIcon {
                iconView
            }
            
            Text(monthYear)
                .anchorTextStyle(size.titleStyle)
                .foregroundColor(ANCHORDesign.Colors.textPrimary)
            
            Spacer()
            
            if showEntryCount {
                Text(entryCountText)
                    .anchorTextStyle(size.subtitleStyle)
                    .foregroundColor(ANCHORDesign.Colors.textSecondary)
            }
        }
    }
    
    @ViewBuilder
    private var centeredLayout: some View {
        VStack(spacing: size.contentSpacing) {
            HStack(spacing: size.iconSpacing) {
                if showIcon {
                    iconView
                }
                
                Text(monthYear)
                    .anchorTextStyle(size.titleStyle)
                    .foregroundColor(ANCHORDesign.Colors.textPrimary)
            }
            
            if showEntryCount {
                Text(entryCountText)
                    .anchorTextStyle(size.subtitleStyle)
                    .foregroundColor(ANCHORDesign.Colors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var iconView: some View {
        if let icon = icon {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(iconColor ?? ANCHORDesign.Colors.primary)
        }
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
                .background(badgeColor ?? ANCHORDesign.Colors.primary)
                .cornerRadius(8)
                .offset(x: 8, y: -8)
        }
    }
    
    @ViewBuilder
    private var dividerView: some View {
        Rectangle()
            .fill(dividerColor ?? ANCHORDesign.Colors.textTertiary.opacity(0.3))
            .frame(height: 1)
            .padding(.horizontal, headerPadding.leading)
    }
    
    @ViewBuilder
    private var progressView: some View {
        if let progressValue = progressValue {
            ProgressView(value: progressValue)
                .progressViewStyle(LinearProgressViewStyle(tint: progressColor ?? ANCHORDesign.Colors.primary))
                .scaleEffect(x: 1, y: 0.5)
                .padding(.horizontal, 2)
        }
    }
    
    @ViewBuilder
    private var headerBackground: some View {
        Group {
            switch style {
            case .standard:
                ANCHORDesign.Colors.backgroundCard
            case .elevated:
                ANCHORDesign.Colors.backgroundCard
            case .outlined:
                ANCHORDesign.Colors.backgroundCard
                    .overlay(
                        RoundedRectangle(cornerRadius: headerCornerRadius)
                            .stroke(ANCHORDesign.Colors.textTertiary.opacity(0.2), lineWidth: 1)
                    )
            case .gradient:
                LinearGradient(
                    colors: [
                        ANCHORDesign.Colors.primary.opacity(0.1),
                        ANCHORDesign.Colors.primary.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .glassmorphism:
                ANCHORDesign.Colors.primary.opacity(0.05)
                    .background(.ultraThinMaterial)
            case .minimal:
                Color.clear
            }
        }
    }
    
    // MARK: - Helper Methods
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
}

// MARK: - Supporting Types
extension MonthHeaderCard {
    enum HeaderStyle {
        case standard
        case elevated
        case outlined
        case gradient
        case glassmorphism
        case minimal
        
        var shadow: ANCHORDesign.Shadow {
            switch self {
            case .standard: return ANCHORDesign.Shadow.small
            case .elevated: return ANCHORDesign.Shadow.medium
            case .outlined: return ANCHORDesign.Shadow.none
            case .gradient: return ANCHORDesign.Shadow.small
            case .glassmorphism: return ANCHORDesign.Shadow.small
            case .minimal: return ANCHORDesign.Shadow.none
            }
        }
    }
    
    enum HeaderSize {
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
            case .large: return ANCHORDesign.Spacing.xs
            case .extraLarge: return ANCHORDesign.Spacing.sm
            }
        }
        
        var iconSpacing: CGFloat {
            switch self {
            case .small: return ANCHORDesign.Spacing.xs
            case .medium: return ANCHORDesign.Spacing.sm
            case .large: return ANCHORDesign.Spacing.sm
            case .extraLarge: return ANCHORDesign.Spacing.md
            }
        }
        
        var titleStyle: ANCHORDesign.Typography.Style {
            switch self {
            case .small: return .callout
            case .medium: return .title3
            case .large: return .title2
            case .extraLarge: return .title1
            }
        }
        
        var subtitleStyle: ANCHORDesign.Typography.Style {
            switch self {
            case .small: return .caption1
            case .medium: return .caption1
            case .large: return .callout
            case .extraLarge: return .body
            }
        }
    }
    
    enum Layout {
        case horizontal
        case vertical
        case compact
        case centered
    }
}

// MARK: - View Modifier
private struct AppearanceModifier: ViewModifier {
    @Binding var hasAppeared: Bool
    @Binding var isPressed: Bool
    @Binding var isHovered: Bool
    
    let animateOnAppear: Bool
    let hoverEffect: Bool
    let scaleOnPress: Bool
    let accessibilityLabel: String
    let accessibilityHint: String?
    let accessibilityValue: String?
    let isInteractive: Bool
    let onAppear: () -> Void
    let onHover: (Bool) -> Void
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scaleEffect)
            .opacity(hasAppeared || !animateOnAppear ? 1.0 : 0.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPressed)
            .animation(.easeOut(duration: 0.6), value: hasAppeared)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onAppear {
                if animateOnAppear {
                    withAnimation(.easeOut(duration: 0.6).delay(Double.random(in: 0...0.2))) {
                        hasAppeared = true
                    }
                } else {
                    hasAppeared = true
                }
                onAppear()
            }
            .onHover { hovering in
                onHover(hovering)
            }
            .accessibilityLabel(accessibilityLabel)
            .accessibilityHint(accessibilityHint ?? "")
            .accessibilityValue(accessibilityValue ?? "")
            .accessibilityAddTraits(isInteractive ? .isButton : .isHeader)
    }
    
    private var scaleEffect: CGFloat {
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
}

#Preview("Month Header Cards") {
    ScrollView {
        LazyVStack(spacing: 16) {
            // Standard headers
            MonthHeaderCard(
                monthYear: "January 2024",
                entryCount: 15,
                animateOnAppear: true
            )
            
            MonthHeaderCard(
                monthYear: "December 2023",
                entryCount: 1,
                style: .elevated,
                showIcon: true,
                icon: "calendar",
                showBadge: true,
                badgeText: "NEW"
            )
            
            MonthHeaderCard(
                monthYear: "November 2023",
                entryCount: 23,
                style: .gradient,
                showProgress: true,
                progressValue: 0.75,
                showDivider: true
            )
            
            // Different layouts
            MonthHeaderCard(
                monthYear: "October 2023",
                entryCount: 8,
                style: .outlined,
                layout: .vertical,
                showIcon: true,
                icon: "leaf.fill",
                iconColor: ANCHORDesign.Colors.success
            )
            
            MonthHeaderCard(
                monthYear: "September 2023",
                entryCount: 0,
                style: .glassmorphism,
                size: .large,
                layout: .compact,
            )
            
            MonthHeaderCard(
                monthYear: "August 2023",
                entryCount: 42,
                style: .minimal,
                size: .extraLarge,
                layout: .centered,
                showIcon: true,
                icon: "star.fill",
                iconColor: ANCHORDesign.Colors.warning
            )
        }
        .padding()
    }
}
