import SwiftUI

// MARK: - Color Palette
struct AppTheme {
    // MARK: - Base Colors
    static let primary = Color("Primary")
    static let secondary = Color("Accent")
    static let background = Color(UIColor.systemBackground)
    static let cardBackground = Color(UIColor.secondarySystemBackground)
    static let textPrimary = Color.primary
    static let textSecondary = Color.secondary
    
    // MARK: - Semantic Colors
    static let success = Color.green
    static let warning = Color.orange
    static let error = Color.red
    static let info = Color.blue
    
    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        gradient: Gradient(colors: [primary, primary.opacity(0.8)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let secondaryGradient = LinearGradient(
        gradient: Gradient(colors: [secondary, secondary.opacity(0.8)]),
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Shadows
    static let shadow = Color.black.opacity(0.1)
    static let cardShadow = ShadowStyle(
        color: shadow,
        radius: 8,
        x: 0,
        y: 2
    )
    
    // MARK: - Opacity
    struct Opacity {
        static let disabled: Double = 0.5
        static let medium: Double = 0.7
        static let low: Double = 0.3
    }
}

// MARK: - Shadow Style
struct ShadowStyle {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
    
    func apply() -> some ViewModifier {
        Modifier(shadow: self)
    }
    
    private struct Modifier: ViewModifier {
        let shadow: ShadowStyle
        
        func body(content: Content) -> some View {
            content.shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
        }
    }
}

// MARK: - View Extensions
extension View {
    func cardStyle(backgroundColor: Color = AppTheme.cardBackground) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(12)
            .shadow(
                color: AppTheme.shadow,
                radius: AppTheme.cardShadow.radius,
                x: AppTheme.cardShadow.x,
                y: AppTheme.cardShadow.y
            )
    }
    
    func withShadow(_ shadow: ShadowStyle) -> some View {
        self.shadow(
            color: shadow.color,
            radius: shadow.radius,
            x: shadow.x,
            y: shadow.y
        )
    }
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.primary)
            .cornerRadius(12)
            .opacity(isEnabled ? 1.0 : 0.6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(AppTheme.primary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(AppTheme.primary.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(AppTheme.primary, lineWidth: 1)
            )
            .cornerRadius(12)
            .opacity(isEnabled ? 1.0 : 0.6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview Provider
struct AppTheme_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Color Samples
            HStack(spacing: 10) {
                colorSample("Primary", color: AppTheme.primary)
                colorSample("Secondary", color: AppTheme.secondary)
                colorSample("Background", color: AppTheme.background)
                colorSample("Card", color: AppTheme.cardBackground)
            }
            
            // Button Styles
            VStack(spacing: 16) {
                Button("Primary Button") {}
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal)
                
                Button("Secondary Button") {}
                    .buttonStyle(SecondaryButtonStyle())
                    .padding(.horizontal)
                
                Button("Disabled Button") {}
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(true)
                    .padding(.horizontal)
            }
            .padding(.vertical)
            .cardStyle()
            .padding()
            
            // Card Style
            Text("Card Style")
                .frame(maxWidth: .infinity, minHeight: 100)
                .cardStyle()
                .padding(.horizontal)
            
            Spacer()
        }
        .padding()
    }
    
    private static func colorSample(_ name: String, color: Color) -> some View {
        VStack {
            color
                .frame(width: 60, height: 60)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
            Text(name)
                .font(.caption2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 70)
    }
}
