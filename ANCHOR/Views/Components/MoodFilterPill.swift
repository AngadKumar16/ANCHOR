//
//  MoodFilterPill.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

// MARK: - Supporting Types

enum PillStyle {
    case filled
    case outlined
    case ghost
    case minimal
}

enum PillSize {
    case small
    case medium
    case large
    case extraLarge
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small: return 8
        case .medium: return ANCHORDesign.Spacing.sm
        case .large: return ANCHORDesign.Spacing.md
        case .extraLarge: return ANCHORDesign.Spacing.lg
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return ANCHORDesign.Spacing.xs
        case .large: return ANCHORDesign.Spacing.sm
        case .extraLarge: return ANCHORDesign.Spacing.sm
        }
    }
    
    var iconSpacing: CGFloat {
        switch self {
        case .small: return 4
        case .medium: return ANCHORDesign.Spacing.xs
        case .large: return ANCHORDesign.Spacing.xs
        case .extraLarge: return ANCHORDesign.Spacing.sm
        }
    }
    
    var font: Font {
        switch self {
        case .small: return .caption2
        case .medium: return ANCHORDesign.Typography.Style.caption1.font
        case .large: return ANCHORDesign.Typography.Style.callout.font
        case .extraLarge: return ANCHORDesign.Typography.Style.body.font
        }
    }
}

enum PillShape {
    case capsule
    case roundedRectangle(CGFloat)
    case circle
}

enum IconPosition {
    case leading
    case trailing
}

struct MoodFilterPill: View {
    // MARK: - Core Properties
    let title: String
    let icon: String?
    let color: Color
    let isSelected: Bool
    let onTap: () -> Void
    
    // MARK: - Customization Properties
    let style: PillStyle
    let size: PillSize
    let shape: PillShape
    let showIcon: Bool
    let iconPosition: IconPosition
    let showBadge: Bool
    let badgeCount: Int?
    let badgeColor: Color?
    let isEnabled: Bool
    let showRipple: Bool
    let customPadding: EdgeInsets?
    let customFont: Font?
    let customBackground: AnyView?
    let customBorder: (color: Color, width: CGFloat)?
    
    // MARK: - Animation Properties
    let animateSelection: Bool
    let animateOnAppear: Bool
    let bounceOnTap: Bool
    let hapticFeedback: Bool
    let selectionFeedback: UIImpactFeedbackGenerator.FeedbackStyle
    
    // MARK: - Accessibility Properties
    let accessibilityLabel: String?
    let accessibilityHint: String?
    let accessibilityValue: String?
    
    // MARK: - State
    @State private var hasAppeared = false
    @State private var isPressed = false
    @State private var showRippleEffect = false
    
    // MARK: - Initializers
    init(
        title: String,
        icon: String? = nil,
        color: Color,
        isSelected: Bool,
        onTap: @escaping () -> Void,
        style: PillStyle = .filled,
        size: PillSize = .medium,
        shape: PillShape = .capsule,
        showIcon: Bool = true,
        iconPosition: IconPosition = .leading,
        showBadge: Bool = false,
        badgeCount: Int? = nil,
        badgeColor: Color? = nil,
        isEnabled: Bool = true,
        showRipple: Bool = false,
        customPadding: EdgeInsets? = nil,
        customFont: Font? = nil,
        customBackground: AnyView? = nil,
        customBorder: (color: Color, width: CGFloat)? = nil,
        animateSelection: Bool = true,
        animateOnAppear: Bool = false,
        bounceOnTap: Bool = true,
        hapticFeedback: Bool = true,
        selectionFeedback: UIImpactFeedbackGenerator.FeedbackStyle = .light,
        accessibilityLabel: String? = nil,
        accessibilityHint: String? = nil,
        accessibilityValue: String? = nil
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isSelected = isSelected
        self.onTap = onTap
        self.style = style
        self.size = size
        self.shape = shape
        self.showIcon = showIcon
        self.iconPosition = iconPosition
        self.showBadge = showBadge
        self.badgeCount = badgeCount
        self.badgeColor = badgeColor
        self.isEnabled = isEnabled
        self.showRipple = showRipple
        self.customPadding = customPadding
        self.customFont = customFont
        self.customBackground = customBackground
        self.customBorder = customBorder
        self.animateSelection = animateSelection
        self.animateOnAppear = animateOnAppear
        self.bounceOnTap = bounceOnTap
        self.hapticFeedback = hapticFeedback
        self.selectionFeedback = selectionFeedback
        self.accessibilityLabel = accessibilityLabel
        self.accessibilityHint = accessibilityHint
        self.accessibilityValue = accessibilityValue
    }
    
    // MARK: - Computed Properties
    private var pillPadding: EdgeInsets {
        customPadding ?? EdgeInsets(
            top: size.verticalPadding,
            leading: size.horizontalPadding,
            bottom: size.verticalPadding,
            trailing: size.horizontalPadding
        )
    }
    
    private var pillFont: Font {
        customFont ?? size.font
    }
    
    private var iconSize: CGFloat {
        switch size {
        case .small: return 12
        case .medium: return 14
        case .large: return 16
        case .extraLarge: return 18
        }
    }
    
    private var foregroundColor: Color {
        if !isEnabled {
            return ANCHORDesign.Colors.textTertiary
        }
        
        switch style {
        case .filled:
            return isSelected ? .white : color
        case .outlined:
            return isSelected ? .white : color
        case .ghost:
            return color
        case .minimal:
            return isSelected ? color : ANCHORDesign.Colors.textSecondary
        }
    }
    
    private var scaleEffect: CGFloat {
        if isPressed && bounceOnTap {
            return 0.95
        } else if isSelected && animateSelection {
            return 1.05
        } else if hasAppeared || !animateOnAppear {
            return 1.0
        } else {
            return 0.8
        }
    }
    
    var body: some View {
        Button(action: handleTap) {
            pillContent
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .scaleEffect(scaleEffect)
        .opacity(getOpacity())
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
        }
        .accessibilityLabel(accessibilityLabel ?? title)
        .accessibilityHint(accessibilityHint ?? "Filter by \(title)")
        .accessibilityValue(accessibilityValue ?? (isSelected ? "Selected" : "Not selected"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    // MARK: - Pill Content
    @ViewBuilder
    private var pillContent: some View {
        Group {
            if let customBg = customBackground {
                mainContent
                    .background(AnyView(customBg))
            } else {
                mainContent
                    .padding(pillPadding)
                    .background(pillBackground)
                    .clipShape(pillShape)
            }
        }
        .overlay(pillBorder)
        .overlay(alignment: .topTrailing) {
            if showBadge {
                badgeView
            }
        }
        .overlay {
            if showRipple && showRippleEffect {
                rippleEffect
            }
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        HStack(spacing: size.iconSpacing) {
            if showIcon && icon != nil && iconPosition == .leading {
                iconView
            }
            
            Text(title)
                .font(pillFont)
                .foregroundColor(foregroundColor)
                .lineLimit(1)
            
            if showIcon && icon != nil && iconPosition == .trailing {
                iconView
            }
        }
    }
    
    @ViewBuilder
    private var iconView: some View {
        if let icon = icon {
            Image(systemName: icon)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundColor(foregroundColor)
        }
    }
    
    @ViewBuilder
    private var badgeView: some View {
        if let badgeCount = badgeCount, badgeCount > 0 {
            Text("\(badgeCount)")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(minWidth: 16, minHeight: 16)
                .background(badgeColor ?? ANCHORDesign.Colors.error)
                .clipShape(Circle())
                .offset(x: 8, y: -8)
        } else if badgeCount == nil && showBadge {
            Circle()
                .fill(badgeColor ?? ANCHORDesign.Colors.error)
                .frame(width: 8, height: 8)
                .offset(x: 6, y: -6)
        }
    }
    
    @ViewBuilder
    private var pillBackground: some View {
        Group {
            switch style {
            case .filled:
                if isSelected {
                    color
                } else {
                    color.opacity(0.1)
                }
                
            case .outlined:
                if isSelected {
                    color
                } else {
                    Color.clear
                }
                
            case .ghost:
                if isSelected {
                    color.opacity(0.2)
                } else {
                    Color.clear
                }
                
            case .minimal:
                if isSelected {
                    color.opacity(0.1)
                } else {
                    Color.clear
                }
            }
        }
    }
    
    // MARK: - Shape Helpers
    
    private var pillShape: some Shape {
        switch shape {
        case .capsule:
            return AnyShape(Capsule())
        case .roundedRectangle(let cornerRadius):
            return AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        case .circle:
            return AnyShape(Circle())
        }
    }
    
    private var pillBorder: some View {
        Group {
            if let customBorder = customBorder {
                switch shape {
                case .capsule:
                    Capsule().stroke(customBorder.color, lineWidth: customBorder.width)
                case .roundedRectangle(let radius):
                    RoundedRectangle(cornerRadius: radius)
                        .stroke(customBorder.color, lineWidth: customBorder.width)
                case .circle:
                    Circle().stroke(customBorder.color, lineWidth: customBorder.width)
                }
            } else {
                switch style {
                case .filled:
                    if !isSelected {
                        switch shape {
                        case .capsule:
                            Capsule().stroke(color.opacity(0.3), lineWidth: 1)
                        case .roundedRectangle(let radius):
                            RoundedRectangle(cornerRadius: radius)
                                .stroke(color.opacity(0.3), lineWidth: 1)
                        case .circle:
                            Circle().stroke(color.opacity(0.3), lineWidth: 1)
                        }
                    } else {
                        EmptyView()
                    }
                    
                case .outlined:
                    switch shape {
                    case .capsule:
                        Capsule().stroke(color, lineWidth: isSelected ? 2 : 1)
                    case .roundedRectangle(let radius):
                        RoundedRectangle(cornerRadius: radius)
                            .stroke(color, lineWidth: isSelected ? 2 : 1)
                    case .circle:
                        Circle().stroke(color, lineWidth: isSelected ? 2 : 1)
                    }
                    
                case .ghost:
                    if isSelected {
                        switch shape {
                        case .capsule:
                            Capsule().stroke(color.opacity(0.5), lineWidth: 1)
                        case .roundedRectangle(let radius):
                            RoundedRectangle(cornerRadius: radius)
                                .stroke(color.opacity(0.5), lineWidth: 1)
                        case .circle:
                            Circle().stroke(color.opacity(0.5), lineWidth: 1)
                        }
                    }
                    
                case .minimal:
                    EmptyView()
                }
            }
        }
    }
    
    @ViewBuilder
    private var rippleEffect: some View {
        Circle()
            .stroke(color.opacity(0.3), lineWidth: 2)
            .scaleEffect(showRippleEffect ? 1.5 : 0.8)
            .opacity(showRippleEffect ? 0 : 0.8)
            .animation(.easeOut(duration: 0.6), value: showRippleEffect)
    }
    
    // MARK: - Helper Methods
    private func getOpacity() -> Double {
        if !isEnabled {
            return 0.5
        } else if hasAppeared || !animateOnAppear {
            return 1.0
        } else {
            return 0.0
        }
    }
    
    private func handleTap() {
        if hapticFeedback {
            let impactFeedback = UIImpactFeedbackGenerator(style: selectionFeedback)
            impactFeedback.impactOccurred()
        }
        
        if bounceOnTap {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    self.isPressed = false
                }
            }
        }
        
        if showRipple {
            showRippleEffect = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                self.showRippleEffect = false
            }
        }
        
        onTap()
    }
}

// MARK: - Preview Provider

#Preview("Mood Filter Pills") {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Standard pills
                VStack(alignment: .leading, spacing: 8) {
                    Text("Standard Style")
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        MoodFilterPill(
                            title: "Happy",
                            icon: "face.smiling.fill",
                            color: ANCHORDesign.Colors.moodHappy,
                            isSelected: true,
                            onTap: {}
                        )
                        
                        MoodFilterPill(
                            title: "Calm",
                            icon: "leaf.fill",
                            color: ANCHORDesign.Colors.moodNeutral,
                            isSelected: false,
                            onTap: {}
                        )
                        
                        MoodFilterPill(
                            title: "Anxious",
                            icon: "cloud.rain.fill",
                            color: ANCHORDesign.Colors.moodAnxious,
                            isSelected: false,
                            onTap: {},
                            showBadge: true,
                            badgeCount: 3
                        )
                    }
                }
                
                // Different styles
                VStack(alignment: .leading, spacing: 8) {
                    Text("Different Styles")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            MoodFilterPill(
                                title: "Outlined",
                                icon: "heart.fill",
                                color: ANCHORDesign.Colors.error,
                                isSelected: true,
                                onTap: {},
                                style: .outlined
                            )
                            
                            MoodFilterPill(
                                title: "Ghost",
                                icon: "star.fill",
                                color: ANCHORDesign.Colors.warning,
                                isSelected: false,
                                onTap: {},
                                style: .ghost
                            )
                            
                            MoodFilterPill(
                                title: "Minimal",
                                color: ANCHORDesign.Colors.primary,
                                isSelected: true,
                                onTap: {},
                                style: .minimal,
                                showIcon: false
                            )
                        }
                    }
                }
                
                // Different sizes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Different Sizes")
                        .font(.headline)
                    
                    VStack(spacing: 8) {
                        MoodFilterPill(
                            title: "Small",
                            icon: "circle.fill",
                            color: ANCHORDesign.Colors.accent,
                            isSelected: true,
                            onTap: {},
                            size: .small
                        )
                        
                        MoodFilterPill(
                            title: "Medium",
                            icon: "circle.fill",
                            color: ANCHORDesign.Colors.accent,
                            isSelected: false,
                            onTap: {},
                            size: .medium
                        )
                        
                        MoodFilterPill(
                            title: "Large",
                            icon: "circle.fill",
                            color: ANCHORDesign.Colors.accent,
                            isSelected: false,
                            onTap: {},
                            size: .large
                        )
                        
                        MoodFilterPill(
                            title: "Extra Large",
                            icon: "circle.fill",
                            color: ANCHORDesign.Colors.accent,
                            isSelected: false,
                            onTap: {},
                            size: .extraLarge
                        )
                    }
                }
                
                // Different shapes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Different Shapes")
                        .font(.headline)
                    
                    HStack(spacing: 8) {
                        MoodFilterPill(
                            title: "Capsule",
                            color: ANCHORDesign.Colors.success,
                            isSelected: true,
                            onTap: {},
                            shape: .capsule,
                            showIcon: false
                        )
                        
                        MoodFilterPill(
                            title: "Rounded",
                            color: ANCHORDesign.Colors.success,
                            isSelected: false,
                            onTap: {},
                            shape: .roundedRectangle(8),
                            showIcon: false
                        )
                    }
                }
            }
            .padding()
        }
    }
