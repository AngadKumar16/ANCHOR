import Foundation
import Combine

final class JournalEntryViewViewModel: ObservableObject {
    @Published var items: [JournalEntryViewModel] = []
    @Published var draftTitle: String = ""
    @Published var draftBody: String = ""

    init() {
        self.items = [JournalEntryViewModel(title: "Welcome to JournalEntryView", body: "Auto-added")]
    }

    func saveDraft() async {
        guard !draftTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let m = JournalEntryViewModel(title: draftTitle, body: draftBody)
        do {
            try await JournalEntryViewRepository.shared.save(m)

        // attempt backend post (best-effort)
        do {
            _ = try await APIClient.shared.postJournalEntryView(m)
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
            let remote = try await APIClient.shared.fetchJournalEntryViews()
            if !remote.isEmpty {
                await MainActor.run {
                    self.items = remote
                }
                return
            }
        } catch { }

        do {
            let local = try await JournalEntryViewRepository.shared.fetchAll()
            await MainActor.run {
                self.items = local
            }
        } catch { }
    }
}
