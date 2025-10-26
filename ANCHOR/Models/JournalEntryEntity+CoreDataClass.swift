import Foundation
import CoreData

@objc(JournalEntryEntity)
public class JournalEntryEntity: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var title: String?
    @NSManaged public var body: String?
    @NSManaged public var bodyFormat: String?
    @NSManaged public var sentiment: Double
    @NSManaged public var isLocked: Bool
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var version: Int32
    @NSManaged public var tags: NSSet?
}
