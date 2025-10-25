//
//  JournalEntryEntity+CoreDataProperties.swift
//  ANCHOR
//
//  Created by Angad Kumar on 10/25/25.
//
//

public import Foundation
public import CoreData


public typealias JournalEntryEntityCoreDataPropertiesSet = NSSet

extension JournalEntryEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<JournalEntryEntity> {
        return NSFetchRequest<JournalEntryEntity>(entityName: "JournalEntryEntity")
    }

    @NSManaged public var bodyEncrypted: Data?
    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var sentiment: Int16
    @NSManaged public var tags: String?
    @NSManaged public var title: String?

}

extension JournalEntryEntity : Identifiable {

}
