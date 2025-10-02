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
            let posted = try await APIClient.shared.postEntryCategorizationtaggingViewModel(m)
            // ignore for now
        } catch { }

            DispatchQueue.main.async { self.items.append(m); draftTitle = ""; draftBody = "" }
        } catch { }
    }

    func loadAll() async {

        // attempt backend fetch (best-effort)
        do {
            let remote = try await APIClient.shared.fetchEntryCategorizationtaggingViewModels()
            if !remote.isEmpty {
                DispatchQueue.main.async { self.items = remote }
                return
            }
        } catch { }

        do {
            self.items = try await EntryCategorizationtaggingViewModelRepository.shared.fetchAll()
        } catch { }
    }
}
