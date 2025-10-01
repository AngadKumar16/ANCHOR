import Foundation
import Combine

final class SecureNotes1759356716ViewModel: ObservableObject {
    @Published var title: String = "SecureNotes"
    @Published var items: [String] = []

    func saveEntry(_ s: String) {
        guard !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        items.append(s)
    }

    func load() async {
        try? await Task.sleep(nanoseconds: 200_000_000)
        DispatchQueue.main.async {
            if self.items.isEmpty { self.items = ["Sample entry"] }
        }
    }
}
