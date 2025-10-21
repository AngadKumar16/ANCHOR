import Foundation

/// Base protocol for all view model models
protocol ViewModelModel: Codable, Identifiable {
    var id: UUID { get }
    var title: String { get set }
    var body: String? { get set }
    
    init(id: UUID, title: String, body: String?)
}

extension ViewModelModel {
    init(title: String, body: String? = nil) {
        self.init(id: UUID(), title: title, body: body)
    }
}
