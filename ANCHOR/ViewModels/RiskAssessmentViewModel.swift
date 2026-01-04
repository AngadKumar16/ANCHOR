import Foundation
import CoreData
import os.log

@MainActor
class RiskAssessmentViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    private let logger = OSLog(subsystem: "com.angadkumar16.ANCHOR", category: "RiskAssessment")
    
    @Published var riskScore: Double = 0.0
    @Published var riskReason: String = ""
    @Published var lastAssessmentDate: Date?
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    // Input properties
    @Published var mood: Int = 1  // 0: Low, 1: Neutral, 2: High
    @Published var craving: Double = 0.0
    @Published var triggersText: String = ""
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        Task { await loadLatestAssessment() }
    }
    
    // MARK: - Core Data Operations
    
    private func performOnContext<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let bgContext = context.newBackgroundContext()
        return try await bgContext.perform {
            let result = try block(bgContext)
            if bgContext.hasChanges {
                try bgContext.save()
            }
            return result
        }
    }
    
    func fetchRecent(limit: Int = 5) async throws -> [RiskAssessmentEntity] {
        try await performOnContext { context in
            let request = RiskAssessmentEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \RiskAssessmentEntity.date, ascending: false)]
            request.fetchLimit = limit
            return try context.fetch(request)
        }
    }

    private func loadLatestAssessment() async {
        do {
            let request = RiskAssessmentEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \RiskAssessmentEntity.date, ascending: false)]
            request.fetchLimit = 1
            
            let results = try await performOnContext { context in
                try context.fetch(request)
            }
            
            if let latest = results.first {
                self.riskScore = latest.score
                self.riskReason = latest.reason ?? ""
                self.lastAssessmentDate = latest.date
            }
        } catch {
            os_log("Failed to fetch latest assessment: %{public}@", log: self.logger, type: .error, error.localizedDescription)
        }
    }
    
    func calculateAndSave() async {
        let score = (Double(mood) / 2.0 + craving / 10.0) / 2.0
        let reason = generateRiskReason(score: score)
        
        do {
            try await performOnContext { context in
                let assessment = RiskAssessmentEntity(context: context)
                assessment.id = UUID()
                assessment.date = Date()
                assessment.score = score
                assessment.reason = reason
            }
            
            self.riskScore = score
            self.riskReason = reason
            self.lastAssessmentDate = Date()
            self.alertMessage = "Risk assessment saved successfully"
            self.showAlert = true
        } catch {
            self.alertMessage = "Failed to save assessment: \(error.localizedDescription)"
            self.showAlert = true
        }
    }
    
    private func generateRiskReason(score: Double) -> String {
        switch score {
        case 0..<0.3:
            return "Low risk of relapse. You're doing great!"
        case 0.3..<0.7:
            return "Moderate risk. Be mindful of your triggers."
        default:
            return "High risk. Consider reaching out for support."
        }
    }
}

// MARK: - Preview Support
#if DEBUG
extension RiskAssessmentViewModel {
    static var preview: RiskAssessmentViewModel {
        let viewModel = RiskAssessmentViewModel(context: PersistenceController.preview.container.viewContext)
        viewModel.setupPreviewData()
        return viewModel
    }

    func setupPreviewData() {
        let context = PersistenceController.preview.container.viewContext
        let assessment1 = RiskAssessmentEntity(context: context)
        assessment1.id = UUID()
        assessment1.date = Date().addingTimeInterval(-86400)
        assessment1.score = 25
        assessment1.reason = "Low stress, no strong triggers"

        let assessment2 = RiskAssessmentEntity(context: context)
        assessment2.id = UUID()
        assessment2.date = Date()
        assessment2.score = 65
        assessment2.reason = "Moderate stress, work pressure, lack of sleep"

        do {
            try context.save()
            // Re-fetch to update the view model's state for the preview
            Task { await self.loadLatestAssessment() }
        } catch {
            print("Failed to set up preview data: \(error)")
        }
    }
}
#endif
