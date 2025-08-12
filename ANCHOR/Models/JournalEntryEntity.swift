//
//  JournalEntryEntity.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import Foundation
import CoreData

@objc(JournalEntryEntity)
public class JournalEntryEntity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<JournalEntryEntity> {
        return NSFetchRequest<JournalEntryEntity>(entityName: "JournalEntryEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var title: String?
    @NSManaged public var bodyEncrypted: Data?
    @NSManaged public var sentiment: Int16
    @NSManaged public var tags: String? // CSV
}

// Convenience creator
extension JournalEntryEntity {
    static func create(in context: NSManagedObjectContext,
                       id: UUID = .init(),
                       date: Date = .init(),
                       title: String? = nil,
                       bodyPlain: String,
                       sentiment: Int16 = 0,
                       tagsCSV: String? = nil) throws -> JournalEntryEntity {
        let obj = JournalEntryEntity(context: context)
        obj.id = id
        obj.date = date
        obj.title = title
        obj.sentiment = sentiment
        obj.tags = tagsCSV

        // Encrypt body
        let cipher = try EncryptionService.shared.encryptString(bodyPlain)
        obj.bodyEncrypted = cipher

        return obj
    }

    // Decrypted body convenience
    func decryptedBody() -> String {
        guard let data = bodyEncrypted else { return "" }
        do {
            return try EncryptionService.shared.decryptToString(data)
        } catch {
            Logger.log("Journal decrypt error: \(error)")
            return ""
        }
    }

    func updateBody(_ plain: String) {
        do {
            self.bodyEncrypted = try EncryptionService.shared.encryptString(plain)
        } catch {
            Logger.log("Journal encrypt error: \(error)")
        }
    }

    var tagsArray: [String] {
        if let csv = tags, !csv.isEmpty {
            return csv.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        }
        return []
    }
}
