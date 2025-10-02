import Foundation

struct ConflictResolutionViewModelModel: Codable, Identifiable, Hashable {
    public var id: UUID = UUID()
    public var title: String
    public var createdAt: Date = Date()
    public var body: String?
}
