//
//  JournalEntryEntity+Extensions.swift
//  ANCHOR
//
//  Created by Angad Kumar on 10/26/25.
//

import Foundation
import CoreData

extension JournalEntryEntity {
    // Convert tags NSSet to [String]
    var tagsArray: [String] {
        return (tags as? Set<TagEntity>)?.compactMap { $0.name } ?? []
    }
    
    // Convert to domain model
    func toModel() throws -> JournalEntry? {
        do {
            // Debug print the entity's state
            print("🔍 Converting entity to model - id: \(id), title: \(title ?? "nil")")
            
            let entry = try JournalEntry(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                title: title,
                body: body ?? "",
                bodyFormat: bodyFormat ?? "plain",
                sentiment: sentiment,
                tags: Set(tagsArray),
                isLocked: isLocked,
                version: Int(version)
            )
            
            print("✅ Successfully converted entity to model - id: \(id.uuidString)")
            return entry
            
        } catch {
            print("❌ Error converting JournalEntryEntity to JournalEntry: \(error)")
            print("Entity details - id: \(id.uuidString), title: \(title ?? "nil"), body: \(body?.prefix(20) ?? "nil")...")
            throw error
        }
    }
    
    // Update entity from domain model
    func update(from entry: JournalEntry) {
        guard id == entry.id else { return }
        
        updatedAt = entry.updatedAt
        title = entry.title
        body = entry.body
        bodyFormat = entry.bodyFormat
        sentiment = entry.sentiment ?? 0.0
        isLocked = entry.isLocked
        version = Int32(entry.version)
        
        // Tags are handled by the relationship
    }
    
    // Create or update entity from domain model
    static func updateOrCreate(from entry: JournalEntry, in context: NSManagedObjectContext) throws -> JournalEntryEntity {
        let request: NSFetchRequest<JournalEntryEntity> = fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", entry.id as CVarArg)
        
        let entity = (try? context.fetch(request).first) ?? JournalEntryEntity(context: context)
        
        entity.id = entry.id
        entity.createdAt = entry.createdAt
        entity.updatedAt = entry.updatedAt
        entity.title = entry.title
        entity.body = entry.body
        entity.bodyFormat = entry.bodyFormat
        entity.sentiment = entry.sentiment ?? 0.0
        entity.isLocked = entry.isLocked
        entity.version = Int32(entry.version)
        
        // Handle tags
        if let existingTags = entity.tags as? Set<TagEntity> {
            for tag in existingTags {
                if !entry.tags.contains(tag.name) {
                    tag.mutableSetValue(forKey: "entries").remove(entity)
                    context.delete(tag)
                }
            }
        }
        
        let existingTagNames = (entity.tags as? Set<TagEntity>)?.compactMap { $0.name } ?? []
        
        for tagName in entry.tags where !existingTagNames.contains(tagName) {
            let tag = TagEntity(context: context)
            tag.name = tagName
            entity.addToTags(tag)
        }
        
        return entity
    }
}

// MARK: - Preview Support
#if DEBUG
import SwiftUI

extension JournalEntryEntity {
    @MainActor
    static var preview: JournalEntryEntity {
        let context = PersistenceController.preview.container.viewContext
        let entry = try! JournalEntry(
            title: "Preview Entry",
            body: "This is a preview journal entry.",
            tags: ["preview", "test"],
            isLocked: false
        )
        return try! JournalEntryEntity.updateOrCreate(from: entry, in: context)
    }
}
#endif
