import Foundation

final class EmailpasswordLoginViewModelRepository {
    static let shared = EmailpasswordLoginViewModelRepository()
    private init() {}
    private var store: [EmailpasswordLoginViewModelModel] = []

    func save(_ m: EmailpasswordLoginViewModelModel) async throws {
        store.append(m)
    }
    func fetchAll() async throws -> [EmailpasswordLoginViewModelModel] {
        return store
    }
}
