//
//  ComponentUtilities.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/14/25.
//

import SwiftUI
import Combine

// MARK: - Component Theme Support
struct ComponentTheme {
    static let shared = ComponentTheme()
    
    @AppStorage("component_theme") private var storedTheme: String = "auto"
    
    var currentTheme: ThemeMode {
        ThemeMode(rawValue: storedTheme) ?? .auto
    }
    
    func setTheme(_ theme: ThemeMode) {
        storedTheme = theme.rawValue
    }
    
    enum ThemeMode: String, CaseIterable {
        case light = "light"
        case dark = "dark"
        case auto = "auto"
        
        var displayName: String {
            switch self {
            case .light: return "Light"
            case .dark: return "Dark"
            case .auto: return "Auto"
            }
        }
    }
}

// MARK: - Loading State Management
class ComponentLoadingState: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var error: ComponentError?
    @Published var retryCount: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    func startLoading() {
        isLoading = true
        error = nil
    }
    
    func stopLoading() {
        isLoading = false
    }
    
    func setError(_ error: ComponentError) {
        self.error = error
        isLoading = false
    }
    
    func retry() {
        retryCount += 1
        error = nil
        startLoading()
    }
    
    func reset() {
        isLoading = false
        error = nil
        retryCount = 0
    }
}

// MARK: - Component Error Types
enum ComponentError: LocalizedError, Equatable {
    case networkError(String)
    case dataError(String)
    case validationError(String)
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let message): return "Network Error: \(message)"
        case .dataError(let message): return "Data Error: \(message)"
        case .validationError(let message): return "Validation Error: \(message)"
        case .unknownError(let message): return "Unknown Error: \(message)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .networkError: return "Check your internet connection and try again."
        case .dataError: return "Please refresh the data and try again."
        case .validationError: return "Please check your input and try again."
        case .unknownError: return "Please try again later."
        }
    }
    
    var icon: String {
        switch self {
        case .networkError: return "wifi.slash"
        case .dataError: return "exclamationmark.triangle"
        case .validationError: return "checkmark.circle"
        case .unknownError: return "questionmark.circle"
        }
    }
}

// MARK: - Analytics Integration
class ComponentAnalytics {
    static let shared = ComponentAnalytics()
    
    private init() {}
    
    func trackComponentInteraction(
        component: String,
        action: String,
        properties: [String: Any] = [:]
    ) {
        // In a real app, this would integrate with analytics services
        // like Firebase Analytics, Mixpanel, etc.
        print("📊 Analytics: \(component) - \(action) - \(properties)")
    }
    
    func trackComponentView(component: String, properties: [String: Any] = [:]) {
        trackComponentInteraction(component: component, action: "view", properties: properties)
    }
    
    func trackComponentTap(component: String, properties: [String: Any] = [:]) {
        trackComponentInteraction(component: component, action: "tap", properties: properties)
    }
    
    func trackComponentLongPress(component: String, properties: [String: Any] = [:]) {
        trackComponentInteraction(component: component, action: "long_press", properties: properties)
    }
    
    func trackComponentError(component: String, error: ComponentError, properties: [String: Any] = [:]) {
        var errorProperties = properties
        errorProperties["error_type"] = String(describing: error)
        errorProperties["error_message"] = error.errorDescription
        trackComponentInteraction(component: component, action: "error", properties: errorProperties)
    }
}

// MARK: - Shimmer Loading Effect
struct ShimmerEffect: ViewModifier {
    @State private var isAnimating = false
    
    let gradient = LinearGradient(
        colors: [
            Color.gray.opacity(0.3),
            Color.gray.opacity(0.1),
            Color.gray.opacity(0.3)
        ],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(gradient)
                    .scaleEffect(x: isAnimating ? 1 : 0.8)
                    .opacity(isAnimating ? 0.6 : 0.3)
                    .animation(
                        .easeInOut(duration: 1.2)
                        .repeatForever(autoreverses: true),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

extension View {
    func shimmerEffect() -> some View {
        modifier(ShimmerEffect())
    }
}

// MARK: - Skeleton Loading View
struct SkeletonView: View {
    let height: CGFloat
    let cornerRadius: CGFloat
    
    init(height: CGFloat = 20, cornerRadius: CGFloat = 4) {
        self.height = height
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.3))
            .frame(height: height)
            .shimmerEffect()
    }
}

// MARK: - Error State View
struct ErrorStateView: View {
    let error: ComponentError
    let onRetry: (() -> Void)?
    
    var body: some View {
        VStack(spacing: ANCHORDesign.Spacing.sm) {
            Image(systemName: error.icon)
                .font(.title2)
                .foregroundColor(ANCHORDesign.Colors.error)
            
            Text(error.errorDescription ?? "An error occurred")
                .anchorTextStyle(.callout)
                .foregroundColor(ANCHORDesign.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .anchorTextStyle(.caption1)
                    .foregroundColor(ANCHORDesign.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let onRetry = onRetry {
                Button("Retry", action: onRetry)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
            }
        }
        .padding(ANCHORDesign.Spacing.md)
    }
}

// MARK: - Advanced Animation Utilities
struct SpringAnimation {
    static let gentle = Animation.spring(response: 0.6, dampingFraction: 0.8)
    static let bouncy = Animation.spring(response: 0.4, dampingFraction: 0.6)
    static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.9)
    static let smooth = Animation.easeInOut(duration: 0.3)
    static let quick = Animation.easeInOut(duration: 0.15)
}

// MARK: - Particle Effect View
struct ParticleEffect: View {
    let particleCount: Int
    let colors: [Color]
    @State private var particles: [Particle] = []
    
    init(particleCount: Int = 20, colors: [Color] = [.blue, .purple, .pink]) {
        self.particleCount = particleCount
        self.colors = colors
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(particles.indices, id: \.self) { index in
                    Circle()
                        .fill(particles[index].color)
                        .frame(width: particles[index].size, height: particles[index].size)
                        .position(particles[index].position)
                        .opacity(particles[index].opacity)
                        .scaleEffect(particles[index].scale)
                }
            }
            .onAppear {
                generateParticles(in: geometry.size)
                animateParticles()
            }
        }
    }
    
    private func generateParticles(in size: CGSize) {
        particles = (0..<particleCount).map { _ in
            Particle(
                position: CGPoint(
                    x: CGFloat.random(in: 0...size.width),
                    y: CGFloat.random(in: 0...size.height)
                ),
                color: colors.randomElement() ?? .blue,
                size: CGFloat.random(in: 2...8),
                opacity: Double.random(in: 0.3...1.0),
                scale: CGFloat.random(in: 0.5...1.5)
            )
        }
    }
    
    private func animateParticles() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            for index in particles.indices {
                particles[index].opacity = Double.random(in: 0.1...0.8)
                particles[index].scale = CGFloat.random(in: 0.3...1.2)
            }
        }
    }
    
    struct Particle {
        var position: CGPoint
        let color: Color
        let size: CGFloat
        var opacity: Double
        var scale: CGFloat
    }
}

// MARK: - Advanced Gesture Recognizers
struct AdvancedGestureModifier: ViewModifier {
    let onTap: (() -> Void)?
    let onDoubleTap: (() -> Void)?
    let onLongPress: (() -> Void)?
    let onSwipeLeft: (() -> Void)?
    let onSwipeRight: (() -> Void)?
    let onSwipeUp: (() -> Void)?
    let onSwipeDown: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                onTap?()
            }
            .onTapGesture(count: 2) {
                onDoubleTap?()
            }
            .onLongPressGesture {
                onLongPress?()
            }
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        let horizontalAmount = value.translation.width
                        let verticalAmount = value.translation.height
                        
                        if abs(horizontalAmount) > abs(verticalAmount) {
                            if horizontalAmount < 0 {
                                onSwipeLeft?()
                            } else {
                                onSwipeRight?()
                            }
                        } else {
                            if verticalAmount < 0 {
                                onSwipeUp?()
                            } else {
                                onSwipeDown?()
                            }
                        }
                    }
            )
    }
}

extension View {
    func advancedGestures(
        onTap: (() -> Void)? = nil,
        onDoubleTap: (() -> Void)? = nil,
        onLongPress: (() -> Void)? = nil,
        onSwipeLeft: (() -> Void)? = nil,
        onSwipeRight: (() -> Void)? = nil,
        onSwipeUp: (() -> Void)? = nil,
        onSwipeDown: (() -> Void)? = nil
    ) -> some View {
        modifier(AdvancedGestureModifier(
            onTap: onTap,
            onDoubleTap: onDoubleTap,
            onLongPress: onLongPress,
            onSwipeLeft: onSwipeLeft,
            onSwipeRight: onSwipeRight,
            onSwipeUp: onSwipeUp,
            onSwipeDown: onSwipeDown
        ))
    }
}

// MARK: - Performance Optimization Utilities
class ComponentCache {
    static let shared = ComponentCache()
    private var cache: [String: Any] = [:]
    private let queue = DispatchQueue(label: "component.cache", attributes: .concurrent)
    
    private init() {}
    
    func store<T>(_ value: T, forKey key: String) {
        queue.async(flags: .barrier) {
            self.cache[key] = value
        }
    }
    
    func retrieve<T>(forKey key: String, as type: T.Type) -> T? {
        queue.sync {
            return cache[key] as? T
        }
    }
    
    func remove(forKey key: String) {
        queue.async(flags: .barrier) {
            self.cache.removeValue(forKey: key)
        }
    }
    
    func clear() {
        queue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
}

// MARK: - Keyboard Navigation Support
struct KeyboardNavigationModifier: ViewModifier {
    let onUpArrow: (() -> Void)?
    let onDownArrow: (() -> Void)?
    let onLeftArrow: (() -> Void)?
    let onRightArrow: (() -> Void)?
    let onEnter: (() -> Void)?
    let onEscape: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .focusable()
            .onKeyPress(.upArrow) {
                onUpArrow?()
                return .handled
            }
            .onKeyPress(.downArrow) {
                onDownArrow?()
                return .handled
            }
            .onKeyPress(.leftArrow) {
                onLeftArrow?()
                return .handled
            }
            .onKeyPress(.rightArrow) {
                onRightArrow?()
                return .handled
            }
            .onKeyPress(.return) {
                onEnter?()
                return .handled
            }
            .onKeyPress(.escape) {
                onEscape?()
                return .handled
            }
    }
}

extension View {
    func keyboardNavigation(
        onUpArrow: (() -> Void)? = nil,
        onDownArrow: (() -> Void)? = nil,
        onLeftArrow: (() -> Void)? = nil,
        onRightArrow: (() -> Void)? = nil,
        onEnter: (() -> Void)? = nil,
        onEscape: (() -> Void)? = nil
    ) -> some View {
        modifier(KeyboardNavigationModifier(
            onUpArrow: onUpArrow,
            onDownArrow: onDownArrow,
            onLeftArrow: onLeftArrow,
            onRightArrow: onRightArrow,
            onEnter: onEnter,
            onEscape: onEscape
        ))
    }
}

// MARK: - Context Menu Builder
struct ContextMenuBuilder {
    static func buildMenu(
        for component: String,
        actions: [ContextMenuAction]
    ) -> some View {
        Menu {
            ForEach(actions.indices, id: \.self) { index in
                let action = actions[index]
                
                if action.isDivider {
                    Divider()
                } else {
                    Button(action: {
                        ComponentAnalytics.shared.trackComponentInteraction(
                            component: component,
                            action: "context_menu_\(action.title.lowercased())"
                        )
                        action.handler()
                    }) {
                        Label(action.title, systemImage: action.icon)
                    }
                    .disabled(!action.isEnabled)
                }
            }
        } label: {
            EmptyView()
        }
    }
}

struct ContextMenuAction {
    let title: String
    let icon: String
    let handler: () -> Void
    let isEnabled: Bool
    let isDivider: Bool
    
    init(
        title: String,
        icon: String,
        isEnabled: Bool = true,
        handler: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.handler = handler
        self.isEnabled = isEnabled
        self.isDivider = false
    }
    
    static let divider = ContextMenuAction(
        title: "",
        icon: "",
        isEnabled: false,
        handler: {}
    )
}

// MARK: - Accessibility Enhancements
// MARK: - Accessibility Enhancements

fileprivate struct AccessibilityEnhancementModifier: ViewModifier {
    let label: String
    let hint: String?
    let value: String?
    let traits: AccessibilityTraits
    let actions: [AccessibilityAction]

    func body(content: Content) -> some View {
        // Apply the base modifiers first
        let baseView = content
            .accessibilityLabel(label)
            .accessibilityAddTraits(traits)

        // Conditionally apply hint and value
        let optionalView = baseView
            .modifier(OptionalAccessibility(hint: hint, value: value))

        // Apply all custom actions using a reducer for a clean, chained modification
        actions.reduce(AnyView(optionalView)) { view, action in
            AnyView(view.accessibilityAction(named: action.name, action.handler))
        }
    }
}

fileprivate struct OptionalAccessibility: ViewModifier {
    let hint: String?
    let value: String?

    @ViewBuilder
    func body(content: Content) -> some View {
        if let hint = hint, let value = value {
            content
                .accessibilityHint(hint)
                .accessibilityValue(value)
        } else if let hint = hint {
            content.accessibilityHint(hint)
        } else if let value = value {
            content.accessibilityValue(value)
        } else {
            content
        }
    }
}

extension View {
    func enhanceAccessibility(
        label: String,
        hint: String? = nil,
        value: String? = nil,
        traits: AccessibilityTraits = [],
        actions: [AccessibilityAction] = []
    ) -> some View {
        self.modifier(AccessibilityEnhancementModifier(
            label: label,
            hint: hint,
            value: value,
            traits: traits,
            actions: actions
        ))
    }
}

struct AccessibilityAction {
    let name: String
    let handler: () -> Void
}
