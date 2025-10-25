import Foundation
import CoreData

@objc(JournalEntryEntity)
public class JournalEntryEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var title: String?
    @NSManaged public var body: String
    @NSManaged public var bodyFormat: String
    @NSManaged public var sentiment: Double
    @NSManaged public var isLocked: Bool
    @NSManaged public var version: Int32
    @NSManaged public var tags: Set<TagEntity>?
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<JournalEntryEntity> {
        return NSFetchRequest<JournalEntryEntity>(entityName: "JournalEntryEntity")
    }
    
    static func create(from entry: JournalEntry, in context: NSManagedObjectContext) -> JournalEntryEntity {
        let entity = JournalEntryEntity(context: context)
        entity.id = entry.id
        entity.createdAt = entry.createdAt
        entity.updatedAt = entry.updatedAt
        entity.title = entry.title
        entity.body = entry.body
        entity.bodyFormat = entry.bodyFormat
        entity.sentiment = entry.sentiment ?? 0
        entity.isLocked = entry.isLocked
        entity.version = Int32(entry.version)
        
        // Handle tags
        if !entry.tags.isEmpty {
            let tagEntities = entry.tags.map { tagName -> TagEntity in
                let tagRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
                tagRequest.predicate = NSPredicate(format: "name == %@", tagName)
                tagRequest.fetchLimit = 1
                
                if let existingTag = try? context.fetch(tagRequest).first {
                    return existingTag
                } else {
                    let newTag = TagEntity(context: context)
                    newTag.name = tagName
                    return newTag
                }
            }
            entity.addToTags(Set(tagEntities) as NSSet)
        }
        
        return entity
    }
    
    func update(from entry: JournalEntry) {
        guard id == entry.id else { return }
        
        updatedAt = entry.updatedAt
        title = entry.title
        body = entry.body
        bodyFormat = entry.bodyFormat
        sentiment = entry.sentiment ?? 0
        isLocked = entry.isLocked
        version = Int32(entry.version)
        
        // Update tags if needed
        if let currentTags = tags?.compactMap({ ($0 as? TagEntity)?.name }) {
            let newTags = Set(entry.tags)
            if Set(currentTags) != newTags {
                // Remove old tags
                if let currentTagEntities = tags as? Set<TagEntity> {
                    removeFromTags(currentTagEntities as NSSet)
                }
                
                // Add new tags
                let tagEntities = newTags.map { tagName -> TagEntity in
                    let tagRequest: NSFetchRequest<TagEntity> = TagEntity.fetchRequest()
                    tagRequest.predicate = NSPredicate(format: "name == %@", tagName)
                    tagRequest.fetchLimit = 1
                    
                    if let existingTag = try? managedObjectContext?.fetch(tagRequest).first {
                        return existingTag
                    } else {
                        let newTag = TagEntity(context: managedObjectContext!)
                        newTag.name = tagName
                        return newTag
                    }
                }
                addToTags(Set(tagEntities) as NSSet)
            }
        }
    }
    
    func toModel() -> JournalEntry? {
        guard let context = managedObjectContext else { return nil }
        
        let tagNames = (tags as? Set<TagEntity>)?.compactMap { $0.name } ?? []
        
        return try? JournalEntry(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            title: title,
            body: body,
            bodyFormat: bodyFormat,
            sentiment: sentiment,
            tags: Set(tagNames),
            isLocked: isLocked,
            version: Int(version)
        )
    }
}

// MARK: - Preview Support
#if DEBUG
extension JournalEntryEntity {
    static var preview: JournalEntryEntity {
        let context = PersistenceController.preview.container.viewContext
        let entry = try! JournalEntry(
            title: "Preview Entry",
            body: "This is a preview journal entry.",
            tags: ["preview", "test"],
            isLocked: false
        )
        return JournalEntryEntity.create(from: entry, in: context)
    }
}
#endif
