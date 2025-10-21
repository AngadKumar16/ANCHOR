import Foundation
import CoreData

@MainActor
final class RiskAssessmentViewModel: ObservableObject {
    @Published var mood: Int = 1
    @Published var craving: Double = 0
    @Published var triggersText: String = ""
    @Published var latestResult: RiskAssessmentEntity?

    private let ctx: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.ctx = context
    }

    func calculateAndSave() {
        let triggerCount = triggersText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter{ !$0.isEmpty }.count
        var score = craving * 8.0
        if mood == 2 { score += 15 } else if mood == 0 { score += 5 }
        score += Double(min(triggerCount,5)) * 5.0
        score = min(max(score, 0.0), 100.0)
        let reason = "Craving: \(Int(craving)), Triggers: \(triggerCount), Mood: \(mood)"
        
        Task {
            do {
                let result = try await withCheckedThrowingContinuation { continuation in
                    self.ctx.perform {
                        do {
                            let entity = RiskAssessmentEntity.create(in: self.ctx, score: score, reason: reason)
                            try self.ctx.save()
                            continuation.resume(returning: entity)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
                await MainActor.run {
                    self.latestResult = result
                }
            } catch {
                Logger.log("Risk save failed: \(error)")
            }
        }
    }

    func fetchRecent(limit: Int = 10) -> [RiskAssessmentEntity] {
        let req: NSFetchRequest<RiskAssessmentEntity> = RiskAssessmentEntity.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        req.fetchLimit = limit
        do {
            return try ctx.fetch(req)
        } catch {
            Logger.log("Risk fetch failed: \(error)")
            return []
        }
    }
}
