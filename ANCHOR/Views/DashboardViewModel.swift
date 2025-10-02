import Foundation

struct DashboardViewModel: Codable, Identifiable, Hashable {
    public var id: UUID = UUID()
    public var title: String
    public var createdAt: Date = Date()
    public var body: String?
}
