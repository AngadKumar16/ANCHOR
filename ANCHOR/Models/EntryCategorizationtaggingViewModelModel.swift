import Foundation

struct EntryCategorizationtaggingViewModelModel: ViewModelModel {
    var id: UUID
    var title: String
    var body: String?
    
    init(id: UUID = UUID(), title: String, body: String? = nil) {
        self.id = id
        self.title = title
        self.body = body
    }
}
