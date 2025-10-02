import Foundation
import Combine

final class ImplementUserAuthenticationServiceViewModelViewModel: ObservableObject {
    @Published var items: [ImplementUserAuthenticationServiceViewModelModel] = []
    @Published var draftTitle: String = ""
    @Published var draftBody: String = ""

    init() {
        self.items = [ImplementUserAuthenticationServiceViewModelModel(title: "Welcome to ImplementUserAuthenticationServiceViewModel", body: "Auto-added")]
    }

    func saveDraft() async {
        guard !draftTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let m = ImplementUserAuthenticationServiceViewModelModel(title: draftTitle, body: draftBody)
        do {
            try await ImplementUserAuthenticationServiceViewModelRepository.shared.save(m)

        // attempt backend post (best-effort)
        do {
            let posted = try await APIClient.shared.postImplementUserAuthenticationServiceViewModel(m)
            // ignore for now
        } catch { }

            DispatchQueue.main.async { self.items.append(m); draftTitle = ""; draftBody = "" }
        } catch { }
    }

    func loadAll() async {

        // attempt backend fetch (best-effort)
        do {
            let remote = try await APIClient.shared.fetchImplementUserAuthenticationServiceViewModels()
            if !remote.isEmpty {
                DispatchQueue.main.async { self.items = remote }
                return
            }
        } catch { }

        do {
            self.items = try await ImplementUserAuthenticationServiceViewModelRepository.shared.fetchAll()
        } catch { }
    }
}
