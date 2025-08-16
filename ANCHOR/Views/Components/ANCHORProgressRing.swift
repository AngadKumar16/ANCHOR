//
//  ANCHORProgressRing.swift
//  ANCHOR
//
//  Created by Cascade on 8/14/25.
//

import SwiftUI

struct ANCHORProgressRing: View {
    let progress: Double
    let lineWidth: CGFloat
    let size: CGFloat
    let foregroundColor: Color
    let backgroundColor: Color

    init(
        progress: Double,
        lineWidth: CGFloat = 12,
        size: CGFloat = 120,
        foregroundColor: Color = ANCHORDesign.Colors.accent,
        backgroundColor: Color = ANCHORDesign.Colors.backgroundSecondary
    ) {
        self.progress = progress
        self.lineWidth = lineWidth
        self.size = size
        self.foregroundColor = foregroundColor
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        ZStack {
            // Background Ring
            Circle()
                .stroke(backgroundColor, lineWidth: lineWidth)

            // Foreground Ring
            Circle()
                .trim(from: 0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                .foregroundColor(foregroundColor)
                .rotationEffect(Angle(degrees: -90))
                .animation(.linear, value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Previews
struct ANCHORProgressRing_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 30) {
            ANCHORProgressRing(progress: 0.75)
            ANCHORProgressRing(progress: 0.25, foregroundColor: .red)
            ANCHORProgressRing(progress: 1.0, foregroundColor: .green)
        }
        .padding()
        .background(ANCHORDesign.Colors.backgroundCard)
    }
}
