import SwiftUI

/// A view that applies a shimmering effect to its content.
///
/// The `ShimmeringView` is highly configurable, allowing for customization of the animation's
/// speed, direction, and the gradient used for the shimmer effect.
public struct ShimmeringView<Content: View>: View {
    
    private let content: () -> Content
    private let config: Configuration
    
    @State private var startPoint: UnitPoint
    @State private var endPoint: UnitPoint
    
    /// Initializes a `ShimmeringView` with custom content and configuration.
    ///
    /// - Parameters:
    ///   - config: The configuration for the shimmering effect.
    ///   - content: A closure that returns the content to be shimmered.
    public init(config: Configuration = .default, @ViewBuilder content: @escaping () -> Content) {
        self.config = config
        self.content = content
        _startPoint = State(initialValue: config.initialLocation.start)
        _endPoint = State(initialValue: config.initialLocation.end)
    }
    
    public var body: some View {
        content()
            .overlay(
                LinearGradient(
                    gradient: config.gradient,
                    startPoint: startPoint,
                    endPoint: endPoint
                )
                .mask(content())
                .opacity(config.opacity)
                .blendMode(.screen)
                .onAppear(perform: { 
                    startAnimation() 
                })
            )
    }
    
    private func startAnimation() {
        withAnimation(
            Animation.linear(duration: config.duration)
                .repeatForever(autoreverses: false)
        ) {
            startPoint = config.finalLocation.start
            endPoint = config.finalLocation.end
        }
    }
}

// MARK: - Configuration

extension ShimmeringView {
    
    public struct Configuration {
        /// The gradient to use for the shimmering effect.
        public let gradient: Gradient
        
        /// The duration of one shimmer animation cycle.
        public let duration: TimeInterval
        
        /// The opacity of the shimmer overlay.
        public let opacity: Double
        
        /// The initial location of the gradient.
        public let initialLocation: (start: UnitPoint, end: UnitPoint)
        
        /// The final location of the gradient.
        public let finalLocation: (start: UnitPoint, end: UnitPoint)
        
        public init(
            gradient: Gradient,
            duration: TimeInterval = 1.5,
            opacity: Double = 0.6,
            initialLocation: (start: UnitPoint, end: UnitPoint) = (start: UnitPoint(x: -1, y: 0.5), end: UnitPoint(x: 0, y: 0.5)),
            finalLocation: (start: UnitPoint, end: UnitPoint) = (start: UnitPoint(x: 1, y: 0.5), end: UnitPoint(x: 2, y: 0.5))
        ) {
            self.gradient = gradient
            self.duration = duration
            self.opacity = opacity
            self.initialLocation = initialLocation
            self.finalLocation = finalLocation
        }
        
        /// A default configuration with a standard shimmer effect.
        public static let `default` = Configuration(
            gradient: Gradient(colors: [.white.opacity(0.5), .white, .white.opacity(0.5)])
        )
    }
}

// MARK: - Previews

struct ShimmeringView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            ShimmeringView {
                Text("Shimmering Text")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            
            ShimmeringView(config: .init(gradient: Gradient(colors: [.red, .blue, .red]))) {
                RoundedRectangle(cornerRadius: 12)
                    .frame(width: 200, height: 100)
            }
        }
        .padding()
        .background(Color.black)
        .previewLayout(.sizeThatFits)
    }
}
