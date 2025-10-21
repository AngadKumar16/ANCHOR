import Foundation
import Combine

final class ConflictResolutionViewModelViewModel: ObservableObject {
    @Published var items: [ConflictResolutionViewModelModel] = []
    @Published var draftTitle: String = ""
    @Published var draftBody: String = ""

    init() {
        self.items = [ConflictResolutionViewModelModel(title: "Welcome to ConflictResolutionViewModel", body: "Auto-added")]
    }

    func saveDraft() async {
        guard !draftTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let m = ConflictResolutionViewModelModel(title: draftTitle, body: draftBody)
        do {
            try await ConflictResolutionViewModelRepository.shared.save(m)

            // attempt backend post (best-effort)
            do {
                _ = try await APIClient.shared.postConflictResolutionViewModel(m)
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
            let remote = try await APIClient.shared.fetchConflictResolutionViewModels()
            if !remote.isEmpty {
                await MainActor.run { [weak self] in
                    self?.items = remote
                }
                return
            }
        } catch { }

        do {
            let local = try await ConflictResolutionViewModelRepository.shared.fetchAll()
            await MainActor.run { [weak self] in
                self?.items = local
            }
        } catch { }
    }
}
