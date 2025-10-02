import Foundation
import Combine

final class MoodTrackingInterfaceViewModelViewModel: ObservableObject {
    @Published var items: [MoodTrackingInterfaceViewModelModel] = []
    @Published var draftTitle: String = ""
    @Published var draftBody: String = ""

    init() {
        self.items = [MoodTrackingInterfaceViewModelModel(title: "Welcome to MoodTrackingInterfaceViewModel", body: "Auto-added")]
    }

    func saveDraft() async {
        guard !draftTitle.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let m = MoodTrackingInterfaceViewModelModel(title: draftTitle, body: draftBody)
        do {
            try await MoodTrackingInterfaceViewModelRepository.shared.save(m)

        // attempt backend post (best-effort)
        do {
            let posted = try await APIClient.shared.postMoodTrackingInterfaceViewModel(m)
            // ignore for now
        } catch { }

            DispatchQueue.main.async { self.items.append(m); draftTitle = ""; draftBody = "" }
        } catch { }
    }

    func loadAll() async {

        // attempt backend fetch (best-effort)
        do {
            let remote = try await APIClient.shared.fetchMoodTrackingInterfaceViewModels()
            if !remote.isEmpty {
                DispatchQueue.main.async { self.items = remote }
                return
            }
        } catch { }

        do {
            self.items = try await MoodTrackingInterfaceViewModelRepository.shared.fetchAll()
        } catch { }
    }
}
