import Foundation
import Combine

final class ImplementBackuprestoreFunctionalityViewModelViewModel: ObservableObject {
    @Published var items: [ImplementBackuprestoreFunctionalityViewModelModel] = []
    @Published var draftTitle: String = ""
    @Published var draftBody: String = ""

    init() {
        self.items = [ImplementBackuprestoreFunctionalityViewModelModel(title: "Welcome to ImplementBackuprestoreFunctionalityViewModel", body: "Auto-added")]
    }

    func saveDraft() async {
        guard !draftTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let m = ImplementBackuprestoreFunctionalityViewModelModel(title: draftTitle, body: draftBody)
        do {
            try await ImplementBackuprestoreFunctionalityViewModelRepository.shared.save(m)

        // attempt backend post (best-effort)
        do {
            let posted = try await APIClient.shared.postImplementBackuprestoreFunctionalityViewModel(m)
            // ignore for now
        } catch { }

            DispatchQueue.main.async { self.items.append(m); draftTitle = ""; draftBody = "" }
        } catch { }
    }

    func loadAll() async {

        // attempt backend fetch (best-effort)
        do {
            let remote = try await APIClient.shared.fetchImplementBackuprestoreFunctionalityViewModels()
            if !remote.isEmpty {
                DispatchQueue.main.async { self.items = remote }
                return
            }
        } catch { }

        do {
            self.items = try await ImplementBackuprestoreFunctionalityViewModelRepository.shared.fetchAll()
        } catch { }
    }
}
