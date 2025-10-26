//
//  SettingsViewModel.swift
//  ANCHOR
//
//  Created by Angad Kumar on 10/26/25.
//

import Foundation
import SwiftUI
import Combine

class SettingsViewModel: ObservableObject {
    @Published var isBiometricEnabled: Bool = false
    @Published var appearance: Appearance = .system
    @Published var notificationsEnabled: Bool = true
    @Published var displayName: String = ""
    
    enum Appearance: String, CaseIterable, Identifiable {
        case light, dark, system
        
        var id: String { self.rawValue }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        loadSettings()
    }
    
    private func loadSettings() {
        // Load settings from UserDefaults
        isBiometricEnabled = UserDefaults.standard.bool(forKey: "isBiometricEnabled")
        notificationsEnabled = UserDefaults.standard.bool(forKey: "notificationsEnabled")
        displayName = UserDefaults.standard.string(forKey: "displayName") ?? ""
        
        if let appearanceRaw = UserDefaults.standard.string(forKey: "appearance"),
           let appearance = Appearance(rawValue: appearanceRaw) {
            self.appearance = appearance
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(isBiometricEnabled, forKey: "isBiometricEnabled")
        UserDefaults.standard.set(notificationsEnabled, forKey: "notificationsEnabled")
        UserDefaults.standard.set(displayName, forKey: "displayName")
        UserDefaults.standard.set(appearance.rawValue, forKey: "appearance")
    }
    
    func updateAppearance() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else { return }
        
        switch appearance {
        case .light:
            window.overrideUserInterfaceStyle = .light
        case .dark:
            window.overrideUserInterfaceStyle = .dark
        case .system:
            window.overrideUserInterfaceStyle = .unspecified
        }
    }
}

// MARK: - Preview Provider
#if DEBUG
extension SettingsViewModel {
    static var preview: SettingsViewModel {
        let viewModel = SettingsViewModel()
        viewModel.displayName = "Test User"
        viewModel.isBiometricEnabled = true
        viewModel.notificationsEnabled = true
        viewModel.appearance = .system
        return viewModel
    }
}
#endif
