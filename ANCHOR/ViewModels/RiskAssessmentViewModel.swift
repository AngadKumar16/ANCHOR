import Foundation
import CoreData

@MainActor
class RiskAssessmentViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    @Published var riskScore: Double = 0.0
    @Published var riskReason: String = ""
    @Published var lastAssessmentDate: Date?
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        fetchLatestAssessment()
    }
    
    func fetchLatestAssessment() {
        let request: NSFetchRequest<RiskAssessmentEntity> = RiskAssessmentEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \RiskAssessmentEntity.date, ascending: false)]
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            if let latest = results.first {
                riskScore = latest.score
                riskReason = latest.reason ?? ""
                lastAssessmentDate = latest.date
            }
        } catch {
            print("Error fetching risk assessment: \(error)")
        }
    }
    
    func saveAssessment(score: Double, reason: String?) {
        let assessment = RiskAssessmentEntity.create(
            in: viewContext,
            date: Date(),
            reason: reason,
            score: score
        )
        
        do {
            try viewContext.save()
            riskScore = score
            riskReason = reason ?? ""
            lastAssessmentDate = assessment.date
            showAlert = true
            alertMessage = "Risk assessment saved successfully"
        } catch {
            print("Error saving risk assessment: \(error)")
            showAlert = true
            alertMessage = "Failed to save risk assessment"
        }
    }
    
    func calculateRiskScore(answers: [Int]) -> Double {
        // Simple average of answers, scaled to 0-1 range
        let total = answers.reduce(0, +)
        let average = Double(total) / Double(answers.count * 5) // Assuming 5-point scale
        return min(max(average, 0), 1) // Clamp between 0 and 1
    }
}
