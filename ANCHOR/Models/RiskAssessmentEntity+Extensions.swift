import CoreData

// MARK: - Identifiable Conformance
extension RiskAssessmentEntity: Identifiable {
    // Core Data already provides an 'id' property through NSManagedObject's objectID
    // This makes it work with SwiftUI's ForEach and other Identifiable requirements
}

// MARK: - Convenience Methods
extension RiskAssessmentEntity {
    static func create(in context: NSManagedObjectContext, date: Date, reason: String?, score: Double) -> RiskAssessmentEntity {
        let assessment = RiskAssessmentEntity(context: context)
        assessment.id = UUID()
        assessment.date = date
        assessment.reason = reason
        assessment.score = score
        return assessment
    }
}
