import Foundation
import Combine

final class EntryCategorizationtaggingViewModelViewModel: ObservableObject {
    @Published var items: [EntryCategorizationtaggingViewModelModel] = []
    @Published var draftTitle: String = ""
    @Published var draftBody: String = ""

    init() {
        self.items = [EntryCategorizationtaggingViewModelModel(title: "Welcome to EntryCategorizationtaggingViewModel", body: "Auto-added")]
    }

    func saveDraft() async {
        guard !draftTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let m = EntryCategorizationtaggingViewModelModel(title: draftTitle, body: draftBody)
        do {
            try await EntryCategorizationtaggingViewModelRepository.shared.save(m)

            // attempt backend post (best-effort)
            do {
                _ = try await APIClient.shared.postEntryCategorizationtaggingViewModel(m)
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
            let remote = try await APIClient.shared.fetchEntryCategorizationtaggingViewModels()
            if !remote.isEmpty {
                await MainActor.run { [weak self] in
                    self?.items = remote
                }
                return
            }
        } catch { }

        do {
            let local = try await EntryCategorizationtaggingViewModelRepository.shared.fetchAll()
            await MainActor.run { [weak self] in
                self?.items = local
            }
        } catch { }
    }
}
