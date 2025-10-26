import SwiftUI

struct SentimentIndicator: View {
    let value: Double // -1.0 to 1.0
    
    private var color: Color {
        switch value {
        case ..<(-0.5): return .red
        case -0.5..<0: return .orange
        case 0: return .gray
        case 0..<0.5: return .yellow
        case 0.5...: return .green
        default: return .gray
        }
    }
    
    private var icon: String {
        switch value {
        case ..<(-0.5): return "hand.thumbsdown.fill"
        case -0.5..<0: return "hand.thumbsdown"
        case 0: return "minus.circle"
        case 0..<0.5: return "hand.thumbsup"
        case 0.5...: return "hand.thumbsup.fill"
        default: return "questionmark.circle"
        }
    }
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            
            Text(String(format: "%.1f", value))
                .font(.caption.monospacedDigit())
                .foregroundColor(color)
        }
        .accessibilityLabel("Sentiment: \(value)")
    }
}

#Preview {
    VStack {
        SentimentIndicator(value: -1.0)
        SentimentIndicator(value: -0.3)
        SentimentIndicator(value: 0.0)
        SentimentIndicator(value: 0.3)
        SentimentIndicator(value: 1.0)
    }
    .padding()
}
