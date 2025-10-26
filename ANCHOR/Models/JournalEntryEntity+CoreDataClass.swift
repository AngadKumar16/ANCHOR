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
    @NSManaged public var tags: String?

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JournalEntryEntity> {
        return NSFetchRequest<JournalEntryEntity>(entityName: "JournalEntryEntity")
    }
    
    // Convert tags string to array
    var tagsArray: [String] {
        get {
            return tags?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []
        }
        set {
            tags = newValue.joined(separator: ",")
        }
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
        entity.tagsArray = Array(entry.tags)
        
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
        tagsArray = Array(entry.tags)
    }
    
    func toModel() -> JournalEntry? {
        guard let context = managedObjectContext else { return nil }
        
        return try? JournalEntry(
            id: id,
            createdAt: createdAt,
            updatedAt: updatedAt,
            title: title,
            body: body,
            bodyFormat: bodyFormat,
            sentiment: sentiment,
            tags: Set(tagsArray),
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
