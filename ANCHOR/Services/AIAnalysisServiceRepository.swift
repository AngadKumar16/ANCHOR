import Foundation

final class AIAnalysisServiceRepository {
    static let shared = AIAnalysisServiceRepository()
    private init() {}
    private var store: [AIAnalysisServiceModel] = []

    func save(_ m: AIAnalysisServiceModel) async throws {
        store.append(m)
    }
    func fetchAll() async throws -> [AIAnalysisServiceModel] {
        return store
    }
}
