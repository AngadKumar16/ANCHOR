//
//  PermissionRequestView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

struct PermissionRequestView: View {
    @EnvironmentObject var appState: AppState
    @State private var notificationEnabled = false
    @State private var healthKitEnabled = false
    @State private var isRequestingPermissions = false
    
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "hand.raised.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Permissions")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Help us personalize your ANCHOR experience")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 40)
            
            // Permission toggles
            VStack(spacing: 20) {
                ForEach(OnboardingPermission.allCases, id: \.self) { permission in
                    PermissionToggleCard(
                        permission: permission,
                        isEnabled: binding(for: permission)
                    )
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: requestPermissions) {
                    HStack {
                        if isRequestingPermissions {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        }
                        Text(isRequestingPermissions ? "Setting up..." : "Continue")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isRequestingPermissions)
                
                Button("Skip for now") {
                    onComplete()
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
    }
    
    private func binding(for permission: OnboardingPermission) -> Binding<Bool> {
        switch permission {
        case .notifications:
            return $notificationEnabled
        case .healthKit:
            return $healthKitEnabled
        }
    }
    
    private func requestPermissions() {
        isRequestingPermissions = true
        
        Task {
            if notificationEnabled {
                _ = await appState.requestNotificationPermission()
            }
            
            if healthKitEnabled {
                _ = await appState.requestHealthKitPermission()
            }
            
            // Schedule daily reminders if notifications are enabled
            if appState.notificationPermissionGranted {
                appState.scheduleDailyReminders()
            }
            
            await MainActor.run {
                isRequestingPermissions = false
                onComplete()
            }
        }
    }
}

private struct PermissionToggleCard: View {
    let permission: OnboardingPermission
    @Binding var isEnabled: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: permission.iconName)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(permission.title)
                    .font(.headline)
                
                Text(permission.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
        }
        .padding(20)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

#Preview {
    PermissionRequestView(onComplete: {})
        .environmentObject(AppState())
}
