//
//  UserProfileEntity+CoreDataProperties.swift
//  ANCHOR
//
//  Created by Angad Kumar on 10/25/25.
//
//

public import Foundation
public import CoreData


public typealias UserProfileEntityCoreDataPropertiesSet = NSSet

extension UserProfileEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfileEntity> {
        return NSFetchRequest<UserProfileEntity>(entityName: "UserProfileEntity")
    }

    @NSManaged public var anonymousId: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var displayName: String?
    @NSManaged public var id: UUID?

}

extension UserProfileEntity : Identifiable {

}
