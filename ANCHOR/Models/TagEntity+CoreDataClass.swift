import Foundation
import CoreData

@objc(TagEntity)
public class TagEntity: NSManagedObject, Identifiable {
    @NSManaged public var name: String
    @NSManaged public var entries: Set<JournalEntryEntity>?
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<TagEntity> {
        return NSFetchRequest<TagEntity>(entityName: "TagEntity")
    }
}

// MARK: - Preview Support
#if DEBUG
extension TagEntity {
    static var preview: TagEntity {
        let context = PersistenceController.preview.container.viewContext
        let tag = TagEntity(context: context)
        tag.name = "preview"
        return tag
    }
}
#endif
