//
//  AppState.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI
import UserNotifications
import HealthKit

@MainActor
class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    @Published var notificationPermissionGranted = false
    @Published var healthKitPermissionGranted = false
    
    private let healthStore = HKHealthStore()
    
    init() {
        checkPermissions()
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
    }
    
    // MARK: - Permission Management
    
    func checkPermissions() {
        checkNotificationPermission()
        checkHealthKitPermission()
    }
    
    private func checkNotificationPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.notificationPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    private func checkHealthKitPermission() {
        guard HKHealthStore.isHealthDataAvailable() else {
            healthKitPermissionGranted = false
            return
        }
        
        let mindfulSessionType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        let status = healthStore.authorizationStatus(for: mindfulSessionType)
        healthKitPermissionGranted = status == .sharingAuthorized
    }
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            await MainActor.run {
                self.notificationPermissionGranted = granted
            }
            return granted
        } catch {
            Logger.log("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    func requestHealthKitPermission() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else {
            return false
        }
        
        let typesToShare: Set<HKSampleType> = [
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ]
        
        let typesToRead: Set<HKObjectType> = [
            HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        ]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            await MainActor.run {
                self.checkHealthKitPermission()
            }
            return healthKitPermissionGranted
        } catch {
            Logger.log("Failed to request HealthKit permission: \(error)")
            return false
        }
    }
    
    // MARK: - Notification Scheduling
    
    func scheduleDailyReminders() {
        guard notificationPermissionGranted else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Check-in"
        content.body = "Take a moment to check in with yourself. How are you feeling today?"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 19 // 7 PM
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyCheckIn", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                Logger.log("Failed to schedule daily reminder: \(error)")
            }
        }
    }
}
