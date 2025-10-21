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
                _ = try await APIClient.shared.postEmailpasswordLoginViewModel(m)
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
            let remote = try await APIClient.shared.fetchEmailpasswordLoginViewModels()
            if !remote.isEmpty {
                await MainActor.run { [weak self] in
                    self?.items = remote
                }
                return
            }
        } catch { }

        do {
            let local = try await EmailpasswordLoginViewModelRepository.shared.fetchAll()
            await MainActor.run { [weak self] in
                self?.items = local
            }
        } catch { }
    }
}
