//
//  UserProfileEntity.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import Foundation
import CoreData

@objc(UserProfileEntity)
public class UserProfileEntity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfileEntity> {
        return NSFetchRequest<UserProfileEntity>(entityName: "UserProfileEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var displayName: String?
    @NSManaged public var anonymousId: String?
    @NSManaged public var createdAt: Date
}

extension UserProfileEntity {
    static func createDefault(in context: NSManagedObjectContext) -> UserProfileEntity {
        let e = UserProfileEntity(context: context)
        e.id = UUID()
        e.createdAt = Date()
        return e
    }
}
