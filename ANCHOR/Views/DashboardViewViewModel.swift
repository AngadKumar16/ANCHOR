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
            let posted = try await APIClient.shared.postDashboardView(m)
            // ignore for now
        } catch { }

            DispatchQueue.main.async { self.items.append(m); draftTitle = ""; draftBody = "" }
        } catch { }
    }

    func loadAll() async {

        // attempt backend fetch (best-effort)
        do {
            let remote = try await APIClient.shared.fetchDashboardViews()
            if !remote.isEmpty {
                DispatchQueue.main.async { self.items = remote }
                return
            }
        } catch { }

        do {
            self.items = try await DashboardViewRepository.shared.fetchAll()
        } catch { }
    }
}
