import Foundation
import SwiftUI
import Combine

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var isBiometricEnabled: Bool
    @Published var appearance: Appearance
    @Published var notificationsEnabled: Bool
    @Published var displayName: String
    
    enum Appearance: String, CaseIterable, Identifiable {
        case light, dark, system
        var id: String { self.rawValue }
    }
    
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        
        // Load initial values
        isBiometricEnabled = userDefaults.bool(forKey: "isBiometricEnabled")
        notificationsEnabled = userDefaults.bool(forKey: "notificationsEnabled")
        displayName = userDefaults.string(forKey: "displayName") ?? ""
        self.appearance = Appearance(rawValue: userDefaults.string(forKey: "appearance") ?? "") ?? .system
        
        // Setup subscribers to automatically save changes
        setupSubscribers()
    }
    
    private func setupSubscribers() {
        $isBiometricEnabled
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "isBiometricEnabled")
            }
            .store(in: &cancellables)
            
        $notificationsEnabled
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "notificationsEnabled")
            }
            .store(in: &cancellables)
            
        $displayName
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: "displayName")
            }
            .store(in: &cancellables)
            
        $appearance
            .dropFirst()
            .sink { [weak self] value in
                self?.userDefaults.set(value.rawValue, forKey: "appearance")
                self?.updateAppearance(with: value)
            }
            .store(in: &cancellables)
    }
    
    private func updateAppearance(with appearance: Appearance) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        
        windowScene.windows.forEach {
            switch appearance {
            case .light:
                $0.overrideUserInterfaceStyle = .light
            case .dark:
                $0.overrideUserInterfaceStyle = .dark
            case .system:
                $0.overrideUserInterfaceStyle = .unspecified
            }
        }
    }
}

// MARK: - Preview Provider
#if DEBUG
extension SettingsViewModel {
    static var preview: SettingsViewModel {
        let defaults = UserDefaults(suiteName: "#preview")!
        defaults.removePersistentDomain(forName: "#preview")
        return SettingsViewModel(userDefaults: defaults)
    }
}
#endif
