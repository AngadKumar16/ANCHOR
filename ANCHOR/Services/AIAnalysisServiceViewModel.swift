import Foundation
import Combine

final class AIAnalysisServiceViewModel: ObservableObject {
    @Published var items: [AIAnalysisServiceModel] = []
    @Published var draftTitle: String = ""
    @Published var draftBody: String = ""

    init() {
        self.items = [AIAnalysisServiceModel(title: "Welcome to AIAnalysisService", body: "Auto-added")]
    }

    func saveDraft() async {
        guard !draftTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let m = AIAnalysisServiceModel(title: draftTitle, body: draftBody)
        do {
            try await AIAnalysisServiceRepository.shared.save(m)

        // attempt backend post (best-effort)
        do {
            _ = try await APIClient.shared.postAIAnalysisService(m)
            // ignore for now
        } catch { }

            await MainActor.run { [items = self.items] in
                self.items = items + [m]
                self.draftTitle = ""
                self.draftBody = ""
            }
        } catch { }
    }

    func loadAll() async {

        // attempt backend fetch (best-effort)
        do {
            let remote = try await APIClient.shared.fetchAIAnalysisServices()
            if !remote.isEmpty {
                await MainActor.run {
                    self.items = remote
                }
                return
            }
        } catch { }

        do {
            let local = try await AIAnalysisServiceRepository.shared.fetchAll()
            await MainActor.run {
                self.items = local
            }
        } catch { }
    }
}
