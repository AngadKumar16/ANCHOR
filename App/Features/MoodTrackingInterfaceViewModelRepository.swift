import Foundation

final class MoodTrackingInterfaceViewModelRepository {
    static let shared = MoodTrackingInterfaceViewModelRepository()
    private init() {}
    private var store: [MoodTrackingInterfaceViewModelModel] = []

    func save(_ m: MoodTrackingInterfaceViewModelModel) async throws {
        store.append(m)
    }
    func fetchAll() async throws -> [MoodTrackingInterfaceViewModelModel] {
        return store
    }
}
