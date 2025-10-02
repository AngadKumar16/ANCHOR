import Foundation

final class ImplementUserAuthenticationServiceViewModelRepository {
    static let shared = ImplementUserAuthenticationServiceViewModelRepository()
    private init() {}
    private var store: [ImplementUserAuthenticationServiceViewModelModel] = []

    func save(_ m: ImplementUserAuthenticationServiceViewModelModel) async throws {
        store.append(m)
    }
    func fetchAll() async throws -> [ImplementUserAuthenticationServiceViewModelModel] {
        return store
    }
}
