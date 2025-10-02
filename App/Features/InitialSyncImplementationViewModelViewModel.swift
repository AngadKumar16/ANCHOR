import Foundation
import Combine

final class InitialSyncImplementationViewModelViewModel: ObservableObject {
    @Published var items: [InitialSyncImplementationViewModelModel] = []
    @Published var draftTitle: String = ""
    @Published var draftBody: String = ""

    init() {
        self.items = [InitialSyncImplementationViewModelModel(title: "Welcome to InitialSyncImplementationViewModel", body: "Auto-added")]
    }

    func saveDraft() async {
        guard !draftTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let m = InitialSyncImplementationViewModelModel(title: draftTitle, body: draftBody)
        do {
            try await InitialSyncImplementationViewModelRepository.shared.save(m)

        // attempt backend post (best-effort)
        do {
            let posted = try await APIClient.shared.postInitialSyncImplementationViewModel(m)
            // ignore for now
        } catch { }

            DispatchQueue.main.async { self.items.append(m); draftTitle = ""; draftBody = "" }
        } catch { }
    }

    func loadAll() async {

        // attempt backend fetch (best-effort)
        do {
            let remote = try await APIClient.shared.fetchInitialSyncImplementationViewModels()
            if !remote.isEmpty {
                DispatchQueue.main.async { self.items = remote }
                return
            }
        } catch { }

        do {
            self.items = try await InitialSyncImplementationViewModelRepository.shared.fetchAll()
        } catch { }
    }
}
