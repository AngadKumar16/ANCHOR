import Foundation

final class ImplementBackuprestoreFunctionalityViewModelRepository {
    static let shared = ImplementBackuprestoreFunctionalityViewModelRepository()
    private init() {}
    private var store: [ImplementBackuprestoreFunctionalityViewModelModel] = []

    func save(_ m: ImplementBackuprestoreFunctionalityViewModelModel) async throws {
        store.append(m)
    }
    func fetchAll() async throws -> [ImplementBackuprestoreFunctionalityViewModelModel] {
        return store
    }
}
