//
//  OnboardingModels.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

struct OnboardingItem: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let imageName: String
    let showsActionButton: Bool
    let backgroundColor: Color
}

class OnboardingData {
    static let items: [OnboardingItem] = [
        OnboardingItem(
            title: "Welcome to ANCHOR",
            description: "Your personal mental health companion to help you stay grounded and find your anchor in life's storms.",
            imageName: "anchor.circle.fill",
            showsActionButton: false,
            backgroundColor: .blue
        ),
        OnboardingItem(
            title: "Journal Your Journey",
            description: "Track your thoughts, feelings, and progress with our intuitive journaling system powered by AI insights.",
            imageName: "book.circle.fill",
            showsActionButton: false,
            backgroundColor: .green
        ),
        OnboardingItem(
            title: "Mindful Moments",
            description: "Take a break with guided breathing exercises, meditations, and daily check-ins to center yourself.",
            imageName: "heart.circle.fill",
            showsActionButton: false,
            backgroundColor: .purple
        ),
        OnboardingItem(
            title: "Risk Assessment",
            description: "Monitor your mental health with quick assessments and get personalized recommendations for support.",
            imageName: "shield.checkerboard",
            showsActionButton: false,
            backgroundColor: .orange
        ),
        OnboardingItem(
            title: "Stay Connected",
            description: "Enable notifications for daily reminders and optional HealthKit integration for comprehensive wellness tracking.",
            imageName: "bell.circle.fill",
            showsActionButton: true,
            backgroundColor: .indigo
        )
    ]
}

enum OnboardingPermission: CaseIterable {
    case notifications
    case healthKit
    
    var title: String {
        switch self {
        case .notifications:
            return "Daily Reminders"
        case .healthKit:
            return "Health Integration"
        }
    }
    
    var description: String {
        switch self {
        case .notifications:
            return "Get gentle reminders to check in with yourself and maintain your wellness routine."
        case .healthKit:
            return "Sync your mindful minutes and wellness data with Apple Health (optional)."
        }
    }
    
    var iconName: String {
        switch self {
        case .notifications:
            return "bell.fill"
        case .healthKit:
            return "heart.text.square.fill"
        }
    }
}
