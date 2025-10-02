import Foundation

final class InitialSyncImplementationViewModelRepository {
    static let shared = InitialSyncImplementationViewModelRepository()
    private init() {}
    private var store: [InitialSyncImplementationViewModelModel] = []

    func save(_ m: InitialSyncImplementationViewModelModel) async throws {
        store.append(m)
    }
    func fetchAll() async throws -> [InitialSyncImplementationViewModelModel] {
        return store
    }
}
