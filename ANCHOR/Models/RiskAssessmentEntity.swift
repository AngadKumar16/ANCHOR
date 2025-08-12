//
//  RiskAssessmentEntity.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import Foundation
import CoreData

@objc(RiskAssessmentEntity)
public class RiskAssessmentEntity: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<RiskAssessmentEntity> {
        return NSFetchRequest<RiskAssessmentEntity>(entityName: "RiskAssessmentEntity")
    }

    @NSManaged public var id: UUID
    @NSManaged public var date: Date
    @NSManaged public var score: Double
    @NSManaged public var reason: String?
}

extension RiskAssessmentEntity {
    static func create(in context: NSManagedObjectContext, score: Double, reason: String?) -> RiskAssessmentEntity {
        let e = RiskAssessmentEntity(context: context)
        e.id = UUID()
        e.date = Date()
        e.score = score
        e.reason = reason
        return e
    }
}
