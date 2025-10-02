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
            let posted = try await APIClient.shared.postAIAnalysisService(m)
            // ignore for now
        } catch { }

            DispatchQueue.main.async { self.items.append(m); draftTitle = ""; draftBody = "" }
        } catch { }
    }

    func loadAll() async {

        // attempt backend fetch (best-effort)
        do {
            let remote = try await APIClient.shared.fetchAIAnalysisServices()
            if !remote.isEmpty {
                DispatchQueue.main.async { self.items = remote }
                return
            }
        } catch { }

        do {
            self.items = try await AIAnalysisServiceRepository.shared.fetchAll()
        } catch { }
    }
}
