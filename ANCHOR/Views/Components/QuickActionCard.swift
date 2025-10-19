//
//  QuickActionCard.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI
import Combine

struct QuickActionCard: View {
    // MARK: - Core Properties
    let title: String
    let subtitle: String?
    let icon: String
    let action: () -> Void
    
    // MARK: - Customization Properties
    let style: CardStyle
    let size: CardSize
    let iconStyle: IconStyle
    let layout: Layout
    let showBadge: Bool
    let badgeText: String?
    let badgeColor: Color
    let isEnabled: Bool
    let showProgress: Bool
    let progressValue: Double
    let customGradient: [Color]?
    let customBackground: AnyView?
    let customPadding: EdgeInsets?
    let customCornerRadius: CGFloat?
    let customShadow: ANCHORDesign.Shadow?
    
    // MARK: - Animation Properties
    let animateOnAppear: Bool
    let bounceOnTap: Bool
    let hoverEffect: Bool
    let hapticFeedback: Bool
    let pulseEffect: Bool
    
    // MARK: - Accessibility Properties
    let accessibilityLabel: String?
    let accessibilityHint: String?
    let accessibilityValue: String?
    
    // MARK: - Advanced Features
    let enableAnalytics: Bool
    let enableCache: Bool
    let enableKeyboardNavigation: Bool
    let enableAdvancedGestures: Bool
    let enableParticleEffects: Bool
    let loadingStateBinding: Binding<ComponentLoadingState>?
    let contextMenuActions: [ContextMenuAction]
    let onTap: (() -> Void)?
    let onDoubleTap: (() -> Void)?
    let onSwipeLeft: (() -> Void)?
    let onSwipeRight: (() -> Void)?
    
    // MARK: - State
    @State private var hasAppeared = false
    @State private var isPressed = false
    @State private var isHovered = false
    @StateObject private var loadingState = ComponentLoadingState()
    @State private var showParticleEffect = false
    
    // MARK: - Initializers
    init(
        title: String,
        subtitle: String? = nil,
        icon: String,
        style: CardStyle = .gradient,
        size: CardSize = .medium,
        iconStyle: IconStyle = .filled,
        layout: Layout = .vertical,
        showBadge: Bool = false,
        badgeText: String? = nil,
        badgeColor: Color = ANCHORDesign.Colors.error,
        isEnabled: Bool = true,
        showProgress: Bool = false,
        progressValue: Double = 0.0,
        customGradient: [Color]? = nil,
        customBackground: AnyView? = nil,
        customPadding: EdgeInsets? = nil,
        customCornerRadius: CGFloat? = nil,
        customShadow: ANCHORDesign.Shadow? = nil,
        animateOnAppear: Bool = false,
        bounceOnTap: Bool = true,
        hoverEffect: Bool = true,
        hapticFeedback: Bool = true,
        pulseEffect: Bool = false,
        enableAnalytics: Bool = true,
        enableCache: Bool = false,
        enableKeyboardNavigation: Bool = false,
        enableAdvancedGestures: Bool = false,
        enableParticleEffects: Bool = false,
        loadingStateBinding: Binding<ComponentLoadingState>? = nil,
        contextMenuActions: [ContextMenuAction] = [],
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        accessibilityValue: String? = nil,
        onTap: (() -> Void)? = nil,
        onDoubleTap: (() -> Void)? = nil,
        onSwipeLeft: (() -> Void)? = nil,
        onSwipeRight: (() -> Void)? = nil,
        action: @escaping () -> Void = {}
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.style = style
        self.size = size
        self.iconStyle = iconStyle
        self.layout = layout
        self.showBadge = showBadge
        self.badgeText = badgeText
        self.badgeColor = badgeColor
        self.isEnabled = isEnabled
        self.showProgress = showProgress
        self.progressValue = progressValue
        self.customGradient = customGradient
        self.customBackground = customBackground
        self.customPadding = customPadding
        self.customCornerRadius = customCornerRadius
        self.customShadow = customShadow
        self.animateOnAppear = animateOnAppear
        self.bounceOnTap = bounceOnTap
        self.hoverEffect = hoverEffect
        self.hapticFeedback = hapticFeedback
        self.pulseEffect = pulseEffect
        self.enableAnalytics = enableAnalytics
        self.enableCache = enableCache
        self.enableKeyboardNavigation = enableKeyboardNavigation
        self.enableAdvancedGestures = enableAdvancedGestures
        self.enableParticleEffects = enableParticleEffects
        self.loadingStateBinding = loadingStateBinding
        self.contextMenuActions = contextMenuActions
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.accessibilityValue = accessibilityValue
        self.onTap = onTap
        self.onDoubleTap = onDoubleTap
        self.onSwipeLeft = onSwipeLeft
        self.onSwipeRight = onSwipeRight
        self.action = action
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
        case .small: return 20
        case .medium: return 24
        case .large: return 32
        case .extraLarge: return 40
        }
    }
    
    private var iconContainerSize: CGFloat {
        switch size {
        case .small: return 36
        case .medium: return 50
        case .large: return 64
        case .extraLarge: return 80
        }
    }
    
    private var gradientColors: [Color] {
        customGradient ?? style.defaultGradient
    }
    
    var body: some View {
        Group {
            if loadingStateBinding?.wrappedValue.isLoading == true {
                loadingView
            } else if let error = loadingStateBinding?.wrappedValue.error {
                errorView(error)
            } else {
                mainCardView
            }
        }
        .onAppear {
            setupComponent()
        }
        .onDisappear {
            cleanupComponent()
        }
    }
    
    @ViewBuilder
    private var mainCardView: some View {
        Group {
            if enableAdvancedGestures {
                cardContent
                    .advancedGestures(
                        onTap: handleTap,
                        onDoubleTap: onDoubleTap,
                        onSwipeLeft: onSwipeLeft,
                        onSwipeRight: onSwipeRight
                    )
            } else if let onTap = onTap {
                Button(action: handleTap) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
        .padding(cardPadding)
        .background(cardBackground)
        .cornerRadius(cardCornerRadius)
        .shadow(
            color: cardShadow.color,
            radius: cardShadow.radius,
            x: cardShadow.x,
            y: cardShadow.y
        )
        .scaleEffect(
            isPressed && bounceOnTap ? 0.95 :
            (hasAppeared || !animateOnAppear ? 1.0 : 0.8)
        )
        .opacity(hasAppeared || !animateOnAppear ? 1.0 : 0.0)
        .scaleEffect(isHovered && hoverEffect ? 1.05 : 1.0)
        .animation(SpringAnimation.bouncy, value: isPressed)
        .animation(SpringAnimation.gentle, value: hasAppeared)
        .animation(SpringAnimation.smooth, value: isHovered)
        .contextMenu {
            if !contextMenuActions.isEmpty {
                contextMenuView
            }
        }
        .overlay {
            if enableParticleEffects && showParticleEffect {
                ParticleEffect(particleCount: 15, colors: [gradientColors.first ?? ANCHORDesign.Colors.primary, (gradientColors.first ?? ANCHORDesign.Colors.primary).opacity(0.7)])
                    .allowsHitTesting(false)
            }
        }
    }
    
    // MARK: - Card Content
    @ViewBuilder
    private var cardContent: some View {
        Group {
            switch layout {
            case .vertical:
                verticalLayout
            case .horizontal:
                horizontalLayout
            case .iconOnly:
                iconOnlyLayout
            case .compact:
                compactLayout
            }
        }
        .overlay(alignment: .topTrailing) {
            if showBadge {
                badgeView
            }
        }
        .overlay(alignment: .bottom) {
            if showProgress {
                progressView
            }
        }
    }
    
    @ViewBuilder
    private var verticalLayout: some View {
        VStack(spacing: size.contentSpacing) {
            iconView
            
            VStack(spacing: size.textSpacing) {
                Text(title)
                    .anchorTextStyle(size.titleStyle)
                    .multilineTextAlignment(.center)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .anchorTextStyle(size.subtitleStyle)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var horizontalLayout: some View {
        HStack(spacing: size.contentSpacing) {
            iconView
            
            VStack(alignment: .leading, spacing: size.textSpacing) {
                Text(title)
                    .anchorTextStyle(size.titleStyle)
                    .multilineTextAlignment(.leading)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .anchorTextStyle(size.subtitleStyle)
                        .multilineTextAlignment(.leading)
                }
            }
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var iconOnlyLayout: some View {
        iconView
    }
    
    @ViewBuilder
    private var compactLayout: some View {
        HStack(spacing: size.contentSpacing) {
            iconView
            
            Text(title)
                .anchorTextStyle(size.titleStyle)
                .multilineTextAlignment(.leading)
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private var iconView: some View {
        ZStack {
            // Icon background
            switch iconStyle {
            case .filled:
                LinearGradient(
                    colors: gradientColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: iconContainerSize, height: iconContainerSize)
                .cornerRadius(size.iconCornerRadius)
                
            case .outlined:
                RoundedRectangle(cornerRadius: size.iconCornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: iconContainerSize, height: iconContainerSize)
                    .background(style.backgroundColor.opacity(0.1))
                    .cornerRadius(size.iconCornerRadius)
                
            case .minimal:
                Circle()
                    .fill(gradientColors.first?.opacity(0.2) ?? ANCHORDesign.Colors.primary.opacity(0.2))
                    .frame(width: iconContainerSize, height: iconContainerSize)
                
            case .none:
                EmptyView()
            }
            
            // Icon
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(iconStyle == .filled ? .white : gradientColors.first)
                .animation(.spring(response: 0.3), value: icon)
        }
    }
    
    @ViewBuilder
    private var badgeView: some View {
        ZStack {
            Circle()
                .fill(badgeColor)
                .frame(width: 20, height: 20)
            
            if let badgeText = badgeText {
                Text(badgeText)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Circle()
                    .fill(.white)
                    .frame(width: 6, height: 6)
            }
        }
        .offset(x: 8, y: -8)
    }
    
    @ViewBuilder
    private var progressView: some View {
        ProgressView(value: progressValue)
            .progressViewStyle(LinearProgressViewStyle(tint: gradientColors.first ?? ANCHORDesign.Colors.primary))
            .scaleEffect(x: 1, y: 0.5)
            .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        Group {
            switch style {
            case .solid:
                style.backgroundColor
            case .gradient:
                LinearGradient(
                    colors: [style.backgroundColor, style.backgroundColor.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .glassmorphism:
                style.backgroundColor.opacity(0.1)
                    .background(.ultraThinMaterial)
            case .outlined:
                style.backgroundColor
                    .overlay(
                        RoundedRectangle(cornerRadius: cardCornerRadius)
                            .stroke(gradientColors.first?.opacity(0.3) ?? ANCHORDesign.Colors.primary.opacity(0.3), lineWidth: 1)
                    )
            }
        }
    }
    
    // MARK: - Loading and Error Views
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: size.contentSpacing) {
            SkeletonView(height: iconSize, cornerRadius: iconSize/2)
                .frame(width: iconSize, height: iconSize)
            SkeletonView(height: 16, cornerRadius: 4)
                .frame(width: 80)
        }
        .padding(cardPadding)
        .background(ANCHORDesign.Colors.backgroundCard)
        .cornerRadius(cardCornerRadius)
    }
    
    @ViewBuilder
    private func errorView(_ error: ComponentError) -> some View {
        ErrorStateView(error: error) {
            loadingStateBinding?.wrappedValue.retry()
        }
        .padding(cardPadding)
        .background(ANCHORDesign.Colors.backgroundCard)
        .cornerRadius(cardCornerRadius)
    }
    
    @ViewBuilder
    private var contextMenuView: some View {
        ForEach(contextMenuActions.indices, id: \.self) { index in
            let action = contextMenuActions[index]
            
            if action.isDivider {
                Divider()
            } else {
                Button(action: {
                    if enableAnalytics {
                        ComponentAnalytics.shared.trackComponentInteraction(
                            component: "QuickActionCard",
                            action: "context_menu_\(action.title.lowercased())"
                        )
                    }
                    action.handler()
                }) {
                    Label(action.title, systemImage: action.icon)
                }
                .disabled(!action.isEnabled)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func setupComponent() {
        if enableAnalytics {
            ComponentAnalytics.shared.trackComponentView(
                component: "QuickActionCard",
                properties: [
                    "title": title,
                    "style": String(describing: style),
                    "layout": String(describing: layout)
                ]
            )
        }
        
        if animateOnAppear {
            withAnimation(SpringAnimation.gentle.delay(Double.random(in: 0...0.2))) {
                hasAppeared = true
            }
        } else {
            hasAppeared = true
        }
    }
    
    private func cleanupComponent() {
        // Cleanup any resources if needed
    }
    
    private func handleTap() {
        if enableAnalytics {
            ComponentAnalytics.shared.trackComponentTap(
                component: "QuickActionCard",
                properties: ["title": title]
            )
        }
        
        if hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        withAnimation(SpringAnimation.quick) {
            isPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(SpringAnimation.quick) {
                isPressed = false
            }
        }
        
        if enableParticleEffects {
            showParticleEffect = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                showParticleEffect = false
            }
        }
        
        action()
    }
}

// MARK: - Supporting Types
extension QuickActionCard {
    enum CardStyle {
        case solid
        case gradient
        case glassmorphism
        case outlined
        
        var backgroundColor: Color {
            switch self {
            case .solid: return ANCHORDesign.Colors.backgroundCard
            case .gradient: return ANCHORDesign.Colors.backgroundCard
            case .glassmorphism: return ANCHORDesign.Colors.backgroundCard
            case .outlined: return ANCHORDesign.Colors.backgroundCard
            }
        }
        
        var shadow: ANCHORDesign.Shadow {
            switch self {
            case .solid: return ANCHORDesign.Shadow.medium
            case .gradient: return ANCHORDesign.Shadow.large
            case .glassmorphism: return ANCHORDesign.Shadow.small
            case .outlined: return ANCHORDesign.Shadow.small
            }
        }
        
        var defaultGradient: [Color] {
            switch self {
            case .solid: return [ANCHORDesign.Colors.primary]
            case .gradient: return [ANCHORDesign.Colors.primary, ANCHORDesign.Colors.primaryLight]
            case .glassmorphism: return [ANCHORDesign.Colors.primary, ANCHORDesign.Colors.accent]
            case .outlined: return [ANCHORDesign.Colors.primary, ANCHORDesign.Colors.primaryLight]
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
            case .small: return ANCHORDesign.CornerRadius.medium
            case .medium: return ANCHORDesign.CornerRadius.large
            case .large: return ANCHORDesign.CornerRadius.extraLarge
            case .extraLarge: return ANCHORDesign.CornerRadius.extraLarge
            }
        }
        
        var iconCornerRadius: CGFloat {
            switch self {
            case .small: return ANCHORDesign.CornerRadius.small
            case .medium: return ANCHORDesign.CornerRadius.medium
            case .large: return ANCHORDesign.CornerRadius.large
            case .extraLarge: return ANCHORDesign.CornerRadius.large
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
            case .small: return .caption1
            case .medium: return .bodyBold
            case .large: return .title3
            case .extraLarge: return .title2
            }
        }
        
        var subtitleStyle: ANCHORDesign.Typography.Style {
            switch self {
            case .small: return .caption2
            case .medium: return .caption1
            case .large: return .callout
            case .extraLarge: return .body
            }
        }
    }
    
    enum IconStyle {
        case filled
        case outlined
        case minimal
        case none
    }
    
    enum Layout {
        case vertical
        case horizontal
        case iconOnly
        case compact
    }
}

#Preview("Quick Action Cards") {
    ScrollView {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
            // Standard cards
            QuickActionCard(
                title: "New Journal",
                subtitle: "Write your thoughts",
                icon: "book.fill",
                customGradient: [ANCHORDesign.Colors.primary, ANCHORDesign.Colors.primary.opacity(0.7)],
                action: {
                    print("New Journal tapped")
                }
            )
            
            QuickActionCard(
                title: "Breathing",
                subtitle: "Calm your mind",
                icon: "wind",
                customGradient: [ANCHORDesign.Colors.accent, ANCHORDesign.Colors.accent.opacity(0.7)],
                action: {
                    print("Breathing tapped")
                }
            )
            
            // Different styles
            QuickActionCard(
                title: "Check-In",
                subtitle: "Daily wellness",
                icon: "heart.fill",
                style: .glassmorphism,
                showBadge: true,
                customGradient: [ANCHORDesign.Colors.moodHappy, ANCHORDesign.Colors.moodVeryHappy]
            ) {
                print("Check-In tapped")
            }
            
            QuickActionCard(
                title: "Progress",
                subtitle: "View stats",
                icon: "chart.line.uptrend.xyaxis",
                style: .outlined,
                showProgress: true,
                progressValue: 0.7,
                customGradient: [ANCHORDesign.Colors.warning, ANCHORDesign.Colors.moodNeutral]
            ) {
                print("Progress tapped")
            }
            
            // Different sizes and layouts
            QuickActionCard(
                title: "Settings",
                icon: "gear",
                style: .solid,
                size: .small,
                iconStyle: .minimal,
                layout: .compact,
            ) {
                print("Settings tapped")
            }
            
            QuickActionCard(
                title: "Emergency",
                subtitle: "Get help now",
                icon: "phone.fill",
                size: .large,
                showBadge: true,
                badgeColor: ANCHORDesign.Colors.error,
                customGradient: [ANCHORDesign.Colors.error, Color.red],
                pulseEffect: true,
            ) {
                print("Emergency tapped")
            }
        }
        .padding()
    }
}
