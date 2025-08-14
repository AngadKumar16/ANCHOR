//
//  StatCard.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

struct StatCard: View {
    // MARK: - Core Properties
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    // MARK: - Customization Properties
    let style: CardStyle
    let size: CardSize
    let layout: Layout
    let showTrend: Bool
    let trendDirection: TrendDirection
    let trendValue: String?
    let showProgress: Bool
    let progressValue: Double
    let showIcon: Bool
    let iconStyle: IconStyle
    let valueFormatter: ValueFormatter
    let customBackground: AnyView?
    let customPadding: EdgeInsets?
    let customCornerRadius: CGFloat?
    let customShadow: ANCHORDesign.Shadow?
    let onTap: (() -> Void)?
    
    // MARK: - Animation Properties
    let animateOnAppear: Bool
    let animateValue: Bool
    let countUpDuration: Double
    let hapticFeedback: Bool
    
    // MARK: - Accessibility Properties
    let accessibilityLabel: String?
    let accessibilityHint: String?
    let accessibilityValue: String?
    
    // MARK: - State
    @State private var hasAppeared = false
    @State private var animatedValue: Double = 0
    @State private var isPressed = false
    
    // MARK: - Initializers
    init(
        title: String,
        value: String,
        icon: String,
        color: Color,
        style: CardStyle = .standard,
        size: CardSize = .medium,
        layout: Layout = .vertical,
        showTrend: Bool = false,
        trendDirection: TrendDirection = .neutral,
        trendValue: String? = nil,
        showProgress: Bool = false,
        progressValue: Double = 0.0,
        showIcon: Bool = true,
        iconStyle: IconStyle = .filled,
        valueFormatter: ValueFormatter = .none,
        customBackground: AnyView? = nil,
        customPadding: EdgeInsets? = nil,
        customCornerRadius: CGFloat? = nil,
        customShadow: ANCHORDesign.Shadow? = nil,
        animateOnAppear: Bool = false,
        animateValue: Bool = false,
        countUpDuration: Double = 1.0,
        hapticFeedback: Bool = false,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        accessibilityValue: String? = nil,
        onTap: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.style = style
        self.size = size
        self.layout = layout
        self.showTrend = showTrend
        self.trendDirection = trendDirection
        self.trendValue = trendValue
        self.showProgress = showProgress
        self.progressValue = progressValue
        self.showIcon = showIcon
        self.iconStyle = iconStyle
        self.valueFormatter = valueFormatter
        self.customBackground = customBackground
        self.customPadding = customPadding
        self.customCornerRadius = customCornerRadius
        self.customShadow = customShadow
        self.animateOnAppear = animateOnAppear
        self.animateValue = animateValue
        self.countUpDuration = countUpDuration
        self.hapticFeedback = hapticFeedback
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.accessibilityValue = accessibilityValue
        self.onTap = onTap
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
        case .medium: return 16
        case .large: return 20
        case .extraLarge: return 24
        }
    }
    
    private var iconContainerSize: CGFloat {
        switch size {
        case .small: return 24
        case .medium: return 32
        case .large: return 40
        case .extraLarge: return 48
        }
    }
    
    private var displayValue: String {
        if animateValue && hasAppeared {
            return formatAnimatedValue(animatedValue)
        }
        return formatValue(value)
    }
    
    private var numericValue: Double {
        Double(value.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) ?? 0
    }
    
    var body: some View {
        Group {
            if let onTap = onTap {
                Button(action: handleTap) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
        .scaleEffect(isPressed ? 0.98 : (hasAppeared || !animateOnAppear ? 1.0 : 0.9))
        .opacity(hasAppeared || !animateOnAppear ? 1.0 : 0.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isPressed)
        .animation(.easeOut(duration: 0.6), value: hasAppeared)
        .onAppear {
            if animateOnAppear {
                withAnimation(.easeOut(duration: 0.6).delay(Double.random(in: 0...0.2))) {
                    hasAppeared = true
                }
            } else {
                hasAppeared = true
            }
            
            if animateValue {
                withAnimation(.easeOut(duration: countUpDuration).delay(0.3)) {
                    animatedValue = numericValue
                }
            }
        }
        .accessibilityLabel(accessibilityLabel ?? "\(title): \(value)")
        .accessibilityHint(accessibilityHint)
        .accessibilityValue(accessibilityValue ?? value)
        .accessibilityAddTraits(onTap != nil ? .isButton : .isStaticText)
    }
    
    // MARK: - Card Content
    @ViewBuilder
    private var cardContent: some View {
        Group {
            if let customBg = customBackground {
                mainContent
                    .background(customBg)
            } else {
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
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        Group {
            switch layout {
            case .vertical:
                verticalLayout
            case .horizontal:
                horizontalLayout
            case .compact:
                compactLayout
            case .featured:
                featuredLayout
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
            // Header with icon and title
            HStack(spacing: size.iconSpacing) {
                if showIcon {
                    iconView
                }
                
                Text(title)
                    .anchorTextStyle(size.titleStyle)
                    .foregroundColor(ANCHORDesign.Colors.textSecondary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                if showTrend {
                    trendView
                }
            }
            
            // Value
            HStack {
                Text(displayValue)
                    .anchorTextStyle(size.valueStyle)
                    .foregroundColor(ANCHORDesign.Colors.textPrimary)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var horizontalLayout: some View {
        HStack(spacing: size.contentSpacing) {
            if showIcon {
                iconView
            }
            
            VStack(alignment: .leading, spacing: size.textSpacing) {
                Text(title)
                    .anchorTextStyle(size.titleStyle)
                    .foregroundColor(ANCHORDesign.Colors.textSecondary)
                
                Text(displayValue)
                    .anchorTextStyle(size.valueStyle)
                    .foregroundColor(ANCHORDesign.Colors.textPrimary)
            }
            
            Spacer()
            
            if showTrend {
                trendView
            }
        }
    }
    
    @ViewBuilder
    private var compactLayout: some View {
        HStack(spacing: size.contentSpacing) {
            if showIcon {
                iconView
            }
            
            Text(title)
                .anchorTextStyle(size.titleStyle)
                .foregroundColor(ANCHORDesign.Colors.textSecondary)
            
            Spacer()
            
            Text(displayValue)
                .anchorTextStyle(size.valueStyle)
                .foregroundColor(ANCHORDesign.Colors.textPrimary)
            
            if showTrend {
                trendView
            }
        }
    }
    
    @ViewBuilder
    private var featuredLayout: some View {
        VStack(spacing: size.contentSpacing) {
            // Large value at top
            Text(displayValue)
                .anchorTextStyle(size.featuredValueStyle)
                .foregroundColor(color)
                .multilineTextAlignment(.center)
            
            // Title and icon below
            HStack(spacing: size.iconSpacing) {
                if showIcon {
                    iconView
                }
                
                Text(title)
                    .anchorTextStyle(size.titleStyle)
                    .foregroundColor(ANCHORDesign.Colors.textSecondary)
                
                if showTrend {
                    trendView
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var iconView: some View {
        ZStack {
            switch iconStyle {
            case .filled:
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: iconContainerSize, height: iconContainerSize)
                
            case .outlined:
                Circle()
                    .stroke(color, lineWidth: 1.5)
                    .frame(width: iconContainerSize, height: iconContainerSize)
                
            case .minimal:
                EmptyView()
            }
            
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(color)
        }
    }
    
    @ViewBuilder
    private var trendView: some View {
        HStack(spacing: 2) {
            Image(systemName: trendDirection.icon)
                .font(.caption2)
                .foregroundColor(trendDirection.color)
            
            if let trendValue = trendValue {
                Text(trendValue)
                    .font(.caption2)
                    .foregroundColor(trendDirection.color)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(trendDirection.color.opacity(0.1))
        .cornerRadius(4)
    }
    
    @ViewBuilder
    private var progressView: some View {
        ProgressView(value: progressValue)
            .progressViewStyle(LinearProgressViewStyle(tint: color))
            .scaleEffect(x: 1, y: 0.5)
            .padding(.horizontal, 2)
    }
    
    @ViewBuilder
    private var cardBackground: some View {
        Group {
            switch style {
            case .standard:
                color.opacity(0.1)
            case .elevated:
                ANCHORDesign.Colors.backgroundCard
            case .outlined:
                ANCHORDesign.Colors.backgroundCard
                    .overlay(
                        RoundedRectangle(cornerRadius: cardCornerRadius)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            case .gradient:
                LinearGradient(
                    colors: [color.opacity(0.1), color.opacity(0.05)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            case .glassmorphism:
                color.opacity(0.05)
                    .background(.ultraThinMaterial)
            }
        }
    }
    
    // MARK: - Helper Methods
    private func handleTap() {
        if hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }
        
        withAnimation(.easeInOut(duration: 0.1)) {
            isPressed = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
        
        onTap?()
    }
    
    private func formatValue(_ value: String) -> String {
        switch valueFormatter {
        case .none:
            return value
        case .number:
            if let number = Double(value) {
                return NumberFormatter.localizedString(from: NSNumber(value: number), number: .decimal)
            }
            return value
        case .currency:
            if let number = Double(value) {
                let formatter = NumberFormatter()
                formatter.numberStyle = .currency
                return formatter.string(from: NSNumber(value: number)) ?? value
            }
            return value
        case .percentage:
            if let number = Double(value) {
                return String(format: "%.1f%%", number)
            }
            return value
        case .abbreviated:
            if let number = Double(value) {
                return abbreviateNumber(number)
            }
            return value
        }
    }
    
    private func formatAnimatedValue(_ animatedValue: Double) -> String {
        switch valueFormatter {
        case .none:
            return String(format: "%.0f", animatedValue)
        case .number:
            return NumberFormatter.localizedString(from: NSNumber(value: animatedValue), number: .decimal)
        case .currency:
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            return formatter.string(from: NSNumber(value: animatedValue)) ?? String(format: "%.0f", animatedValue)
        case .percentage:
            return String(format: "%.1f%%", animatedValue)
        case .abbreviated:
            return abbreviateNumber(animatedValue)
        }
    }
    
    private func abbreviateNumber(_ number: Double) -> String {
        let absNumber = abs(number)
        let sign = number < 0 ? "-" : ""
        
        switch absNumber {
        case 1_000_000_000...:
            return String(format: "%@%.1fB", sign, absNumber / 1_000_000_000)
        case 1_000_000...:
            return String(format: "%@%.1fM", sign, absNumber / 1_000_000)
        case 1_000...:
            return String(format: "%@%.1fK", sign, absNumber / 1_000)
        default:
            return String(format: "%@%.0f", sign, absNumber)
        }
    }
}

// MARK: - Supporting Types
extension StatCard {
    enum CardStyle {
        case standard
        case elevated
        case outlined
        case gradient
        case glassmorphism
        
        var shadow: ANCHORDesign.Shadow {
            switch self {
            case .standard: return ANCHORDesign.Shadow.none
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
            case .small: return ANCHORDesign.Spacing.xs
            case .medium: return ANCHORDesign.Spacing.sm
            case .large: return ANCHORDesign.Spacing.md
            case .extraLarge: return ANCHORDesign.Spacing.lg
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
            case .small: return 2
            case .medium: return ANCHORDesign.Spacing.xs
            case .large: return ANCHORDesign.Spacing.sm
            case .extraLarge: return ANCHORDesign.Spacing.md
            }
        }
        
        var iconSpacing: CGFloat {
            switch self {
            case .small: return 2
            case .medium: return ANCHORDesign.Spacing.xs
            case .large: return ANCHORDesign.Spacing.sm
            case .extraLarge: return ANCHORDesign.Spacing.sm
            }
        }
        
        var textSpacing: CGFloat {
            switch self {
            case .small: return 1
            case .medium: return 2
            case .large: return ANCHORDesign.Spacing.xs
            case .extraLarge: return ANCHORDesign.Spacing.xs
            }
        }
        
        var titleStyle: ANCHORDesign.Typography.Style {
            switch self {
            case .small: return .caption2
            case .medium: return .caption1
            case .large: return .callout
            case .extraLarge: return .body
            }
        }
        
        var valueStyle: ANCHORDesign.Typography.Style {
            switch self {
            case .small: return .callout
            case .medium: return .bodyBold
            case .large: return .title3
            case .extraLarge: return .title2
            }
        }
        
        var featuredValueStyle: ANCHORDesign.Typography.Style {
            switch self {
            case .small: return .title3
            case .medium: return .title2
            case .large: return .title1
            case .extraLarge: return .largeTitle
            }
        }
    }
    
    enum Layout {
        case vertical
        case horizontal
        case compact
        case featured
    }
    
    enum TrendDirection {
        case up
        case down
        case neutral
        
        var icon: String {
            switch self {
            case .up: return "arrow.up"
            case .down: return "arrow.down"
            case .neutral: return "minus"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return ANCHORDesign.Colors.success
            case .down: return ANCHORDesign.Colors.error
            case .neutral: return ANCHORDesign.Colors.textTertiary
            }
        }
    }
    
    enum IconStyle {
        case filled
        case outlined
        case minimal
    }
    
    enum ValueFormatter {
        case none
        case number
        case currency
        case percentage
        case abbreviated
    }
}

#Preview("Stat Cards") {
    ScrollView {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 2), spacing: 16) {
            // Standard cards
            StatCard(
                title: "Total Entries",
                value: "142",
                icon: "book.fill",
                color: ANCHORDesign.Colors.primary,
                animateValue: true
            )
            
            StatCard(
                title: "This Month",
                value: "23",
                icon: "calendar",
                color: ANCHORDesign.Colors.accent,
                showTrend: true,
                trendDirection: .up,
                trendValue: "+15%"
            )
            
            StatCard(
                title: "Writing Streak",
                value: "7",
                icon: "flame.fill",
                color: ANCHORDesign.Colors.warning,
                style: .elevated,
                showProgress: true,
                progressValue: 0.7
            )
            
            StatCard(
                title: "Average Mood",
                value: "8.2",
                icon: "face.smiling.fill",
                color: ANCHORDesign.Colors.moodHappy,
                style: .gradient,
                layout: .featured
            )
            
            // Different styles
            StatCard(
                title: "Recovery Days",
                value: "365",
                icon: "shield.fill",
                color: ANCHORDesign.Colors.success,
                style: .outlined,
                size: .large,
                valueFormatter: .abbreviated
            )
            
            StatCard(
                title: "Completion Rate",
                value: "87.5",
                icon: "checkmark.circle.fill",
                color: ANCHORDesign.Colors.primary,
                style: .glassmorphism,
                layout: .horizontal,
                valueFormatter: .percentage
            )
        }
        .padding()
    }
}
