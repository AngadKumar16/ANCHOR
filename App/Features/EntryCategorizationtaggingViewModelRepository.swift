import Foundation

final class EntryCategorizationtaggingViewModelRepository {
    static let shared = EntryCategorizationtaggingViewModelRepository()
    private init() {}
    private var store: [EntryCategorizationtaggingViewModelModel] = []

    func save(_ m: EntryCategorizationtaggingViewModelModel) async throws {
        store.append(m)
    }
    func fetchAll() async throws -> [EntryCategorizationtaggingViewModelModel] {
        return store
    }
}
