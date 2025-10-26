import SwiftUI

enum ColorSchemePreference: String, Codable, CaseIterable {
    case system
    case light
    case dark
    
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

class ThemeManager: ObservableObject {
    @Published var colorSchemePreference: ColorSchemePreference = .system {
        didSet {
            savePreference()
            updateColorScheme()
        }
    }
    
    static let shared = ThemeManager()
    private let userDefaultsKey = "colorSchemePreference"
    
    private init() {
        loadPreference()
    }
    
    private func loadPreference() {
        if let saved = UserDefaults.standard.string(forKey: userDefaultsKey),
           let preference = ColorSchemePreference(rawValue: saved) {
            colorSchemePreference = preference
        }
    }
    
    private func savePreference() {
        UserDefaults.standard.set(colorSchemePreference.rawValue, forKey: userDefaultsKey)
    }
    
    private func updateColorScheme() {
        UIApplication.shared.windows.first?.overrideUserInterfaceStyle = colorSchemePreference.userInterfaceStyle
    }
}

// MARK: - Preview Provider
struct ThemeManager_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // System (light)
            Text("System (Light)")
                .previewDisplayName("System (Light)")
                .preferredColorScheme(.light)
            
            // System (dark)
            Text("System (Dark)")
                .previewDisplayName("System (Dark)")
                .preferredColorScheme(.dark)
            
            // Light
            Text("Light")
                .previewDisplayName("Light")
                .environment(\.colorScheme, .light)
            
            // Dark
            Text("Dark")
                .previewDisplayName("Dark")
                .environment(\.colorScheme, .dark)
        }
        .padding()
    }
}
