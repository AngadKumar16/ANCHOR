//
//  OnboardingView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentIndex = 0
    @State private var showingPermissions = false
    @State private var showingPrivacyDisclaimer = false
    
    private let onboardingItems = OnboardingData.items
    
    var body: some View {
        ZStack {
            if showingPrivacyDisclaimer {
                PrivacyDisclaimerView(
                    onAccept: completeOnboarding,
                    onDecline: showTermsReview
                )
                .transition(.move(edge: .trailing))
            } else if showingPermissions {
                PermissionRequestView(onComplete: showPrivacyDisclaimer)
                    .environmentObject(appState)
                    .transition(.move(edge: .trailing))
            } else {
                TabView(selection: $currentIndex) {
                    ForEach(Array(onboardingItems.enumerated()), id: \.offset) { index, item in
                        OnboardingCardView(
                            item: item,
                            isLastCard: index == onboardingItems.count - 1,
                            onGetStarted: handleGetStarted,
                            onSkip: skipOnboarding
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea()
                
                // Custom page indicators and navigation
                VStack {
                    Spacer()
                    
                    VStack(spacing: 20) {
                        // Page indicators
                        HStack(spacing: 8) {
                            ForEach(0..<onboardingItems.count, id: \.self) { index in
                                Circle()
                                    .fill(index == currentIndex ? .white : .white.opacity(0.5))
                                    .frame(width: 8, height: 8)
                                    .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
                            }
                        }
                        
                        // Navigation buttons (only show if not on last card)
                        if currentIndex < onboardingItems.count - 1 {
                            HStack(spacing: 20) {
                                if currentIndex > 0 {
                                    Button("Back") {
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            currentIndex -= 1
                                        }
                                    }
                                    .font(.headline)
                                    .foregroundColor(.white.opacity(0.8))
                                }
                                
                                Spacer()
                                
                                Button("Next") {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentIndex += 1
                                    }
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(.white.opacity(0.2))
                                .cornerRadius(20)
                            }
                            .padding(.horizontal, 32)
                        }
                    }
                    .padding(.bottom, 50)
                }
            }
        }
        .animation(.easeInOut(duration: 0.5), value: showingPermissions)
        .animation(.easeInOut(duration: 0.5), value: showingPrivacyDisclaimer)
    }
    
    private func handleGetStarted() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showingPermissions = true
        }
    }
    
    private func skipOnboarding() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showingPermissions = true
        }
    }
    
    private func showPrivacyDisclaimer() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showingPrivacyDisclaimer = true
        }
    }
    
    private func completeOnboarding() {
        appState.completeOnboarding()
    }
    
    private func showTermsReview() {
        // In a real app, this would open Safari or a web view
        // For now, we'll just complete onboarding
        completeOnboarding()
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState())
}
