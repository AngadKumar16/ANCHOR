import Foundation
import Combine

/// Auto-generated ViewModel for 'Password reset flow'
final class PasswordResetFlowViewModel: ObservableObject {
    @Published var title: String = "Password reset flow"
    @Published var items: [String] = []

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Provide mock data for previews
        self.items = ["Sample 1", "Sample 2"]
    }

    /// Placeholder async loader
    func load() async {
        // NOTE: implement real loading from repository / backend
        try? await Task.sleep(nanoseconds: 200_000_000) // 0.2s simulated delay
        DispatchQueue.main.async {
            self.items = ["Loaded item 1", "Loaded item 2"]
        }
    }
    /// Auto-added persistence stub
    func save(_ item: String) {
        guard !item.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        DispatchQueue.main.async { self.items.append(item) }
    }

}
