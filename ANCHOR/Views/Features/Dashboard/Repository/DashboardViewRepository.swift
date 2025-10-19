import Foundation

final class DashboardViewRepository {
    static let shared = DashboardViewRepository()
    private init() {}
    private var store: [DashboardViewModel] = []

    func save(_ m: DashboardViewModel) async throws {
        store.append(m)
    }
    func fetchAll() async throws -> [DashboardViewModel] {
        return store
    }
}
