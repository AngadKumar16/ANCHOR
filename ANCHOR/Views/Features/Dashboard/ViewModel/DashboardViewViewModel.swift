import Foundation
import Combine

final class DashboardViewViewModel: ObservableObject {
    @Published var items: [DashboardViewModel] = []
    @Published var draftTitle: String = ""
    @Published var draftBody: String = ""

    init() {
        self.items = [DashboardViewModel(title: "Welcome to DashboardView", body: "Auto-added")]
    }

    func saveDraft() async {
        guard !draftTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let m = DashboardViewModel(title: draftTitle, body: draftBody)
        do {
            try await DashboardViewRepository.shared.save(m)

        // attempt backend post (best-effort)
        do {
            _ = try await APIClient.shared.postDashboardView(m)
            // ignore for now
        } catch { }

            await MainActor.run { [weak self] in
                guard let self = self else { return }
                self.items.append(m)
                self.draftTitle = ""
                self.draftBody = ""
            }
        } catch { }
    }

    func loadAll() async {
        // attempt backend fetch (best-effort)
        do {
            let remote = try await APIClient.shared.fetchDashboardViews()
            if !remote.isEmpty {
                await MainActor.run {
                    self.items = remote
                }
                return
            }
        } catch { }

        do {
            let local = try await DashboardViewRepository.shared.fetchAll()
            await MainActor.run {
                self.items = local
            }
        } catch { }
    }
}
