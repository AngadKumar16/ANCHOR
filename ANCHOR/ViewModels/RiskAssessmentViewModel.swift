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
    
    // Input properties (not stored in Core Data)
    @Published var mood: Int = 1  // 0: Low, 1: Neutral, 2: High
    @Published var craving: Double = 0.0
    @Published var triggersText: String = ""
    
    init(viewContext: NSManagedObjectContext = PersistenceController.shared.viewContext) {
        self.viewContext = viewContext
        loadLatestAssessment()
    }
    
    // MARK: - Core Data Operations
    
    private func loadLatestAssessment() {
        Task {
            do {
                let request = RiskAssessmentEntity.fetchRequest()
                request.sortDescriptors = [NSSortDescriptor(keyPath: \RiskAssessmentEntity.date, ascending: false)]
                request.fetchLimit = 1
                
                let results = try await performFetch(request)
                await MainActor.run {
                    if let latest = results.first {
                        self.riskScore = latest.score
                        self.riskReason = latest.reason ?? ""
                        self.lastAssessmentDate = latest.date
                        // Note: mood and craving are not stored in Core Data
                    }
                }
            } catch {
                os_log("Failed to fetch latest assessment: %{public}@", 
                      log: self.logger, 
                      type: .error, 
                      error.localizedDescription)
            }
        }
    }
    
    // MARK: - Data Fetching
    
    func fetchRecent(limit: Int = 5) async throws -> [RiskAssessmentEntity] {
        try await performOnContext { context -> [RiskAssessmentEntity] in
            let request = RiskAssessmentEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \RiskAssessmentEntity.date, ascending: false)]
            request.fetchLimit = limit
            return try context.fetch(request)
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
            }
        } catch {
            await MainActor.run {
                self.alertMessage = "Failed to save assessment: \(error.localizedDescription)"
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
    
    // MARK: - Helper Methods
    
    private func performOnContext(_ action: @escaping (NSManagedObjectContext) throws -> Void) async throws {
        try await viewContext.perform {
            try action(self.viewContext)
        }
    }
    
    private func performOnContext<T>(_ action: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await viewContext.perform {
            try action(self.viewContext)
        }
    }
    
    private func performFetch<T>(_ request: NSFetchRequest<T>) async throws -> [T] {
        try await viewContext.perform {
            try self.viewContext.fetch(request)
        }
    }
}

// MARK: - Preview Support
#if DEBUG
extension RiskAssessmentViewModel {
    static var preview: RiskAssessmentViewModel {
        let viewModel = RiskAssessmentViewModel(viewContext: PersistenceController.preview.viewContext)
        viewModel.riskScore = 0.5
        viewModel.riskReason = "Moderate risk. Be mindful of your triggers."
        viewModel.lastAssessmentDate = Date()
        return viewModel
    }
}
#endif
