import SwiftUI

/// A reusable gradient background view that can be used throughout the app.
public struct GradientBackground: View {
    // MARK: - Properties
    
    /// The colors to use for the gradient. Defaults to a soothing blue/purple gradient.
    public let colors: [Color]
    
    /// The direction of the gradient. Defaults to top to bottom.
    public let direction: Gradient.Direction
    
    // MARK: - Initializers
    
    /// Creates a gradient background with the specified colors and direction.
    /// - Parameters:
    ///   - colors: The colors to use for the gradient. Defaults to a soothing blue/purple gradient.
    ///   - direction: The direction of the gradient. Defaults to top to bottom.
    public init(colors: [Color]? = nil, direction: Gradient.Direction = .topToBottom) {
        self.colors = colors ?? [
            ANCHORDesign.Colors.primary,
            ANCHORDesign.Colors.primary.opacity(0.8),
            ANCHORDesign.Colors.background
        ]
        self.direction = direction
    }
    
    // MARK: - Body
    
    public var body: some View {
        LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: direction.startPoint,
            endPoint: direction.endPoint
        )
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Gradient Direction

extension Gradient {
    public enum Direction {
        case topToBottom
        case leadingToTrailing
        case diagonal
        case custom(start: UnitPoint, end: UnitPoint)
        
        public var startPoint: UnitPoint {
            switch self {
            case .topToBottom: return .top
            case .leadingToTrailing: return .leading
            case .diagonal: return .topLeading
            case .custom(let start, _): return start
            }
        }
        
        public var endPoint: UnitPoint {
            switch self {
            case .topToBottom: return .bottom
            case .leadingToTrailing: return .trailing
            case .diagonal: return .bottomTrailing
            case .custom(_, let end): return end
            }
        }
    }
}

// MARK: - Previews

#Preview {
    ZStack {
        GradientBackground()
        Text("Gradient Background")
            .font(.largeTitle)
            .foregroundColor(.white)
    }
}

#Preview {
    ZStack {
        GradientBackground(
            colors: [.blue, .purple, .pink],
            direction: .diagonal
        )
        Text("Custom Gradient")
            .font(.largeTitle)
            .foregroundColor(.white)
    }
}
