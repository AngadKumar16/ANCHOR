import Foundation

final class ConflictResolutionViewModelRepository {
    static let shared = ConflictResolutionViewModelRepository()
    private init() {}
    private var store: [ConflictResolutionViewModelModel] = []

    func save(_ m: ConflictResolutionViewModelModel) async throws {
        store.append(m)
    }
    func fetchAll() async throws -> [ConflictResolutionViewModelModel] {
        return store
    }
}
