import CoreData

// MARK: - Identifiable Conformance
extension RiskAssessmentEntity: Identifiable {
    // Core Data already provides an 'id' property through NSManagedObject's objectID
    // This makes it work with SwiftUI's ForEach and other Identifiable requirements
}

// MARK: - Additional Convenience Methods
extension RiskAssessmentEntity {
    // The create method is already defined in the Core Data class
    // Add any additional convenience methods here
}
