//
//  OnboardingCardView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

struct OnboardingCardView: View {
    let item: OnboardingItem
    let isLastCard: Bool
    let onGetStarted: () -> Void
    let onSkip: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Main content area
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Icon
                    Image(systemName: item.imageName)
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(.white)
                        .frame(width: 120, height: 120)
                        .background(
                            Circle()
                                .fill(.white.opacity(0.2))
                                .blur(radius: 1)
                        )
                    
                    // Text content
                    VStack(spacing: 16) {
                        Text(item.title)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                        
                        Text(item.description)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
                
                // Bottom action area
                VStack(spacing: 16) {
                    if item.showsActionButton {
                        Button(action: onGetStarted) {
                            Text("Get Started")
                                .font(.headline)
                                .foregroundColor(item.backgroundColor)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.white)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal, 32)
                    }
                    
                    if !isLastCard {
                        Button(action: onSkip) {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .padding(.bottom, 8)
                    }
                }
                .padding(.bottom, max(geometry.safeAreaInsets.bottom, 32))
            }
        }
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    item.backgroundColor,
                    item.backgroundColor.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .ignoresSafeArea()
    }
}

#Preview {
    OnboardingCardView(
        item: OnboardingData.items[0],
        isLastCard: false,
        onGetStarted: {},
        onSkip: {}
    )
}
