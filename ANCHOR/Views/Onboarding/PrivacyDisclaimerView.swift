//
//  PrivacyDisclaimerView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

struct PrivacyDisclaimerView: View {
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "shield.checkerboard")
                        .font(.system(size: 60))
                        .foregroundColor(.green)
                    
                    Text("Privacy & Disclaimer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Your privacy and wellbeing are our top priorities")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Disclaimer content
                VStack(alignment: .leading, spacing: 20) {
                    DisclaimerSection(
                        icon: "exclamationmark.triangle.fill",
                        title: "Medical Disclaimer",
                        content: "ANCHOR is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition."
                    )
                    
                    DisclaimerSection(
                        icon: "lock.shield.fill",
                        title: "Data Privacy",
                        content: "Your personal data is encrypted and stored securely on your device. We do not share your journal entries or assessment data with third parties without your explicit consent."
                    )
                    
                    DisclaimerSection(
                        icon: "heart.fill",
                        title: "Crisis Support",
                        content: "If you're experiencing a mental health crisis, please contact emergency services (911) or the National Suicide Prevention Lifeline at 988 immediately."
                    )
                    
                    DisclaimerSection(
                        icon: "doc.text.fill",
                        title: "Terms of Use",
                        content: "By using ANCHOR, you agree to our Terms of Service and Privacy Policy. You can review these documents at any time in the app settings."
                    )
                }
                .padding(.horizontal, 20)
                
                // Action buttons
                VStack(spacing: 12) {
                    Button(action: onAccept) {
                        Text("I Understand & Agree")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: onDecline) {
                        Text("Review Terms")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        .background(Color(.systemBackground))
    }
}

private struct DisclaimerSection: View {
    let icon: String
    let title: String
    let content: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(content)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    PrivacyDisclaimerView(
        onAccept: {},
        onDecline: {}
    )
}
