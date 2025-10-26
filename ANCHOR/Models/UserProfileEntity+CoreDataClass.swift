//
//  UserProfileEntity+CoreDataClass.swift
//  ANCHOR
//
//  Created by Angad Kumar on 10/25/25.
//

import Foundation
import CoreData

@objc(UserProfileEntity)
public class UserProfileEntity: NSManagedObject {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfileEntity> {
        return NSFetchRequest<UserProfileEntity>(entityName: "UserProfileEntity")
    }
    
    @NSManaged public var anonymousId: String?
    @NSManaged public var createdAt: Date
    @NSManaged public var displayName: String?
    @NSManaged public var id: UUID
    @NSManaged public var biometricEnabled: Bool
    
    // Helper method to create a new instance
    static func create(
        in context: NSManagedObjectContext,
        displayName: String? = nil,
        anonymousId: String? = nil,
        biometricEnabled: Bool = false
    ) -> UserProfileEntity {
        let entity = UserProfileEntity(context: context)
        entity.id = UUID()
        entity.createdAt = Date()
        entity.displayName = displayName
        entity.anonymousId = anonymousId ?? UUID().uuidString
        entity.biometricEnabled = biometricEnabled
        return entity
    }
}
