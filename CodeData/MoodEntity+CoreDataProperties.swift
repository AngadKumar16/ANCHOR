//
//  MoodEntity+CoreDataProperties.swift
//  ANCHOR
//
//  Created by Angad Kumar on 10/25/25.
//
//

public import Foundation
public import CoreData


public typealias MoodEntityCoreDataPropertiesSet = NSSet

extension MoodEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MoodEntity> {
        return NSFetchRequest<MoodEntity>(entityName: "MoodEntity")
    }

    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var level: Int16
    @NSManaged public var note: String?

}

extension MoodEntity : Identifiable {

}
