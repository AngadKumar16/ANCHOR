//
//  RecoveryTipCard.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

struct RecoveryTipCard: View {
    // MARK: - Properties
    var title: String
    var message: String
    var systemImage: String?
    var customBackground: AnyView? = nil
    var hoverEffect: Bool = true
    var scaleOnPress: Bool = true
    var hapticFeedback: Bool = true
    var onTap: (() -> Void)? = nil
    
    // MARK: - State
    @State private var isHovered = false
    @State private var hasAppeared = false
    @State private var isPressed = false
    
    // MARK: - Computed Properties
    private var computedOpacity: Double {
        hasAppeared ? 1.0 : 0.0
    }
    
    private var computedAccessibilityLabel: String {
        title
    }
    
    private var computedAccessibilityHint: String? {
        message
    }
    
    private var computedAccessibilityTraits: AccessibilityTraits {
        var traits: AccessibilityTraits = .isButton
        if onTap == nil {
            traits.remove(.isButton)
        }
        return traits
    }
    
    // MARK: - Body
    var body: some View {
        mainContentWrapper
            .opacity(computedOpacity)
            .animation(.easeOut(duration: 0.6), value: hasAppeared)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onAppear(perform: handleAppear)
            .onHover { hovering in
                if hoverEffect {
                    isHovered = hovering
                }
            }
            .accessibilityLabel(computedAccessibilityLabel)
            .accessibilityHint(computedAccessibilityHint ?? "")
            .accessibilityAddTraits(computedAccessibilityTraits)
    }
    
    // MARK: - Content Wrappers
    @ViewBuilder
    private var mainContentWrapper: some View {
        if let onTap = onTap {
            Button(action: onTap) {
                mainContent
                    .scaleEffect(scaleOnPress && isPressed ? 0.98 : 1.0)
                    .opacity(scaleOnPress && isPressed ? 0.9 : 1.0)
            }
            .onHover { hovering in
                if hoverEffect {
                    isHovered = hovering
                }
            }
        } else {
            mainContent
        }
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let systemImage = systemImage {
                    Image(systemName: systemImage)
                        .font(.title3)
                        .foregroundColor(.accentColor)
                }
                Text(title)
                    .font(.headline)
                Spacer()
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(ANCHORDesign.Colors.background)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
    
    // MARK: - Methods
    private func handleAppear() {
        withAnimation {
            hasAppeared = true
        }
    }
}

// MARK: - Previews
struct RecoveryTipCard_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            RecoveryTipCard(
                title: "Daily Reflection",
                message: "Take a moment to reflect on your progress today.",
                systemImage: "book.fill"
            )
            
            RecoveryTipCard(
                title: "Stay Hydrated",
                message: "Remember to drink water throughout the day.",
                systemImage: "drop.fill"
            )
        }
        .padding()
        .frame(width: 300)
    }
}