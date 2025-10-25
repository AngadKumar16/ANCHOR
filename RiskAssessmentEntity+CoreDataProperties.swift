//
//  RiskAssessmentEntity+CoreDataProperties.swift
//  ANCHOR
//
//  Created by Angad Kumar on 10/25/25.
//
//

public import Foundation
public import CoreData


public typealias RiskAssessmentEntityCoreDataPropertiesSet = NSSet

extension RiskAssessmentEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<RiskAssessmentEntity> {
        return NSFetchRequest<RiskAssessmentEntity>(entityName: "RiskAssessmentEntity")
    }

    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var reason: String?
    @NSManaged public var score: Double

}

extension RiskAssessmentEntity : Identifiable {

}
