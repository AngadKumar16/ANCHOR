//
//  SplashScreenView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var showTagline = false
    
    let onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.8),
                    Color.indigo.opacity(0.9),
                    Color.purple.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Animated logo
                VStack(spacing: 20) {
                    Image(systemName: "anchor.circle.fill")
                        .font(.system(size: 120, weight: .light))
                        .foregroundColor(.white)
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 1.0), value: isAnimating)
                    
                    Text("ANCHOR")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .offset(y: isAnimating ? 0 : 20)
                        .animation(.easeOut(duration: 1.0).delay(0.3), value: isAnimating)
                }
                
                // Tagline
                Text("Mental wellness made practical")
                    .font(.title2)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.9))
                    .opacity(showTagline ? 1.0 : 0.0)
                    .offset(y: showTagline ? 0 : 10)
                    .animation(.easeOut(duration: 0.8).delay(1.5), value: showTagline)
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                        .opacity(showTagline ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5).delay(2.0), value: showTagline)
                    
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(showTagline ? 1.0 : 0.0)
                        .animation(.easeOut(duration: 0.5).delay(2.2), value: showTagline)
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Start logo animation immediately
        isAnimating = true
        
        // Show tagline after logo animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) {
            showTagline = true
        }
        
        // Complete splash screen after all animations
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            onComplete()
        }
    }
}

#Preview {
    SplashScreenView(onComplete: {})
}
