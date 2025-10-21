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
                _ = try await APIClient.shared.postImplementBackuprestoreFunctionalityViewModel(m)
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
            let remote = try await APIClient.shared.fetchImplementBackuprestoreFunctionalityViewModels()
            if !remote.isEmpty {
                await MainActor.run { [weak self] in
                    self?.items = remote
                }
                return
            }
        } catch { }

        do {
            let local = try await ImplementBackuprestoreFunctionalityViewModelRepository.shared.fetchAll()
            await MainActor.run { [weak self] in
                self?.items = local
            }
        } catch { }
    }
}
