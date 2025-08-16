import SwiftUI

/// A customizable button component that follows the ANCHOR design system.
struct ANCHORButton: View {
    /// The visual style of the button.
    enum Style {
        case primary
        case secondary
        case outline
        case ghost
        case danger
        
        var backgroundColor: Color {
            switch self {
            case .primary: return ANCHORDesign.Colors.primary
            case .secondary: return ANCHORDesign.Colors.secondary
            case .outline, .ghost: return .clear
            case .danger: return ANCHORDesign.Colors.error
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .primary, .secondary, .danger: return .white
            case .outline: return ANCHORDesign.Colors.primary
            case .ghost: return ANCHORDesign.Colors.textPrimary
            }
        }
        
        var borderColor: Color {
            switch self {
            case .outline: return ANCHORDesign.Colors.primary
            case .ghost: return .clear
            default: return .clear
            }
        }
        
        var borderWidth: CGFloat {
            switch self {
            case .outline: return 1
            default: return 0
            }
        }
    }
    
    /// The size of the button.
    enum Size {
        case small
        case medium
        case large
        
        var verticalPadding: CGFloat {
            switch self {
            case .small: return 8
            case .medium: return 12
            case .large: return 16
            }
        }
        
        var horizontalPadding: CGFloat {
            switch self {
            case .small: return 16
            case .medium: return 24
            case .large: return 32
            }
        }
        
        var font: Font {
            switch self {
            case .small: return ANCHORDesign.Typography.Style.caption1.font
            case .medium: return ANCHORDesign.Typography.Style.body.font
            case .large: return ANCHORDesign.Typography.Style.bodyBold.font
            }
        }
    }
    
    // MARK: - Properties
    
    let title: String
    let style: Style
    let size: Size
    let isLoading: Bool
    let isFullWidth: Bool
    let action: () -> Void
    
    // MARK: - Initialization
    
    init(
        title: String,
        style: Style = .primary,
        size: Size = .medium,
        isLoading: Bool = false,
        isFullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.size = size
        self.isLoading = isLoading
        self.isFullWidth = isFullWidth
        self.action = action
    }
    
    // MARK: - Body
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: style.foregroundColor))
                } else {
                    Text(title)
                        .font(size.font.weight(.semibold))
                        .lineLimit(1)
                }
            }
            .foregroundColor(style.foregroundColor)
            .padding(.vertical, size.verticalPadding)
            .padding(.horizontal, size.horizontalPadding)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .background(style.backgroundColor)
            .cornerRadius(ANCHORDesign.CornerRadius.medium)
            .overlay(
                RoundedRectangle(cornerRadius: ANCHORDesign.CornerRadius.medium)
                    .stroke(style.borderColor, lineWidth: style.borderWidth)
            )
            .opacity(isLoading ? 0.7 : 1.0)
        }
        .disabled(isLoading)
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Previews

#Preview("ANCHOR Buttons") {
    VStack(spacing: 16) {
        ANCHORButton(
            title: "Primary Button",
            style: .primary,
            size: .large
        ) {}
        
        ANCHORButton(
            title: "Secondary Button",
            style: .secondary,
            size: .medium
        ) {}
        
        ANCHORButton(
            title: "Outline Button",
            style: .outline,
            size: .medium
        ) {}
        
        ANCHORButton(
            title: "Ghost Button",
            style: .ghost,
            size: .small
        ) {}
        
        ANCHORButton(
            title: "Danger Button",
            style: .danger,
            size: .medium
        ) {}
        
        ANCHORButton(
            title: "Loading Button",
            style: .primary,
            size: .large,
            isLoading: true
        ) {}
    }
    .padding()
}
