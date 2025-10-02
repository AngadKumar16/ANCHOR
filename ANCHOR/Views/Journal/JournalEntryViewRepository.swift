import Foundation

final class JournalEntryViewRepository {
    static let shared = JournalEntryViewRepository()
    private init() {}
    private var store: [JournalEntryViewModel] = []

    func save(_ m: JournalEntryViewModel) async throws {
        store.append(m)
    }
    func fetchAll() async throws -> [JournalEntryViewModel] {
        return store
    }
}
