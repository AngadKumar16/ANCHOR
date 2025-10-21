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
                _ = try await APIClient.shared.postImplementUserAuthenticationServiceViewModel(m)
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
            let remote = try await APIClient.shared.fetchImplementUserAuthenticationServiceViewModels()
            if !remote.isEmpty {
                await MainActor.run { [weak self] in
                    self?.items = remote
                }
                return
            }
        } catch { }

        do {
            let local = try await ImplementUserAuthenticationServiceViewModelRepository.shared.fetchAll()
            await MainActor.run { [weak self] in
                self?.items = local
            }
        } catch { }
    }
}
