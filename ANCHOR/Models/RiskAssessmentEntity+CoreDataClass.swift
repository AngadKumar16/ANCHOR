//
//  RiskAssessmentEntity+CoreDataClass.swift
//  ANCHOR
//
//  Created by Angad Kumar on 10/25/25.
//

import Foundation
import CoreData

@objc(RiskAssessmentEntity)
public class RiskAssessmentEntity: NSManagedObject {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RiskAssessmentEntity> {
        return NSFetchRequest<RiskAssessmentEntity>(entityName: "RiskAssessmentEntity")
    }
    
    @NSManaged public var date: Date
    @NSManaged public var id: UUID
    @NSManaged public var reason: String?
    @NSManaged public var score: Double
    
    // Helper method to create a new instance
    static func create(in context: NSManagedObjectContext, date: Date = Date(), reason: String? = nil, score: Double) -> RiskAssessmentEntity {
        let entity = RiskAssessmentEntity(context: context)
        entity.id = UUID()
        entity.date = date
        entity.reason = reason
        entity.score = score
        return entity
    }
}
