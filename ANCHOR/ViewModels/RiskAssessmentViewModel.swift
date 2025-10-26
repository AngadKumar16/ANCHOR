import Foundation
import CoreData
import os.log

@MainActor
class RiskAssessmentViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext
    private let logger = OSLog(subsystem: "com.angadkumar16.ANCHOR", category: "RiskAssessment")
    
    @Published var riskScore: Double = 0.0
    @Published var riskReason: String = ""
    @Published var lastAssessmentDate: Date?
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    @Published var mood: Int = 1
    @Published var craving: Double = 0
    @Published var triggersText: String = ""
    
    init(viewContext: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.viewContext = viewContext
        Task {
            await fetchLatestAssessment()
        }
    }
    
    // MARK: - Core Data Operations
    
    private func performOnContext<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await viewContext.perform {
            try block(self.viewContext)
        }
    }
    
    func fetchLatestAssessment() async {
        do {
            let assessment = try await performOnContext { context -> RiskAssessmentEntity? in
                let request: NSFetchRequest<RiskAssessmentEntity> = RiskAssessmentEntity.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \RiskAssessmentEntity.date, ascending: false)]
                request.fetchLimit = 1
                
                let results = try context.fetch(request)
                return results.first
            }
            
            if let latest = assessment {
                await MainActor.run {
                    self.riskScore = latest.score
                    self.riskReason = latest.reason ?? ""
                    self.lastAssessmentDate = latest.date
                }
            }
        } catch {
            os_log("❌ Error fetching risk assessment: %{public}@", 
                  log: logger, 
                  type: .error, 
                  error.localizedDescription)
            await MainActor.run {
                self.alertMessage = "Failed to load risk assessment: \(error.localizedDescription)"
                self.showAlert = true
            }
        }
    }
    
    func fetchRecent(limit: Int = 5) async -> [RiskAssessmentEntity] {
        do {
            return try await performOnContext { context in
                let request: NSFetchRequest<RiskAssessmentEntity> = RiskAssessmentEntity.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \RiskAssessmentEntity.date, ascending: false)]
                request.fetchLimit = limit
                return try context.fetch(request)
            }
        } catch {
            os_log("❌ Error fetching recent assessments: %{public}@", 
                  log: logger, 
                  type: .error, 
                  error.localizedDescription)
            return []
        }
    }
    
    // MARK: - Risk Assessment Logic
    
    func calculateAndSave() async {
        do {
            let score = (Double(mood) / 2.0 + craving / 10.0) / 2.0
            let reason = generateRiskReason(score: score)
            
            try await performOnContext { context in
                let assessment = RiskAssessmentEntity(context: context)
                assessment.id = UUID()
                assessment.date = Date()
                assessment.score = score
                assessment.reason = reason
                assessment.mood = Int16(self.mood)
                assessment.craving = self.craving
                assessment.triggers = self.triggersText
                
                if context.hasChanges {
                    try context.save()
                }
            }
            
            await MainActor.run {
                self.riskScore = score
                self.riskReason = reason
                self.lastAssessmentDate = Date()
                self.alertMessage = "Risk assessment saved successfully"
                self.showAlert = true
                
                // Reset form
                self.mood = 1
                self.craving = 0
                self.triggersText = ""
            }
            
        } catch {
            os_log("❌ Error saving risk assessment: %{public}@", 
                  log: logger, 
                  type: .error, 
                  error.localizedDescription)
            await MainActor.run {
                self.alertMessage = "Failed to save risk assessment: \(error.localizedDescription)"
                self.showAlert = true
            }
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
        let viewModel = RiskAssessmentViewModel(viewContext: PersistenceController.preview.container.viewContext)
        viewModel.riskScore = 0.5
        viewModel.riskReason = "Moderate risk. Be mindful of your triggers."
        viewModel.lastAssessmentDate = Date()
        return viewModel
    }
}
#endif
