import Foundation
import Combine

final class EmailpasswordLoginViewModelViewModel: ObservableObject {
    @Published var items: [EmailpasswordLoginViewModelModel] = []
    @Published var draftTitle: String = ""
    @Published var draftBody: String = ""

    init() {
        self.items = [EmailpasswordLoginViewModelModel(title: "Welcome to EmailpasswordLoginViewModel", body: "Auto-added")]
    }

    func saveDraft() async {
        guard !draftTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let m = EmailpasswordLoginViewModelModel(title: draftTitle, body: draftBody)
        do {
            try await EmailpasswordLoginViewModelRepository.shared.save(m)

        // attempt backend post (best-effort)
        do {
            let posted = try await APIClient.shared.postEmailpasswordLoginViewModel(m)
            // ignore for now
        } catch { }

            DispatchQueue.main.async { self.items.append(m); draftTitle = ""; draftBody = "" }
        } catch { }
    }

    func loadAll() async {

        // attempt backend fetch (best-effort)
        do {
            let remote = try await APIClient.shared.fetchEmailpasswordLoginViewModels()
            if !remote.isEmpty {
                DispatchQueue.main.async { self.items = remote }
                return
            }
        } catch { }

        do {
            self.items = try await EmailpasswordLoginViewModelRepository.shared.fetchAll()
        } catch { }
    }
}
