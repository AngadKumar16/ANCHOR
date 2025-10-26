import Foundation
import UIKit
import CoreData

final class DataExportService {
    static let shared = DataExportService()
    private init() {}

    func exportAllJournalEntries(presenting viewController: UIViewController?) {
        let ctx = PersistenceController.shared.container.viewContext
        let req: NSFetchRequest<JournalEntryEntity> = JournalEntryEntity.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntryEntity.createdAt, ascending: false)]
        
        do {
            let results = try ctx.fetch(req)
            // Convert to JournalEntryModel
            let models = results.map { entity -> JournalEntryModel in
                return JournalEntryModel(
                    id: entity.id,
                    date: entity.createdAt,
                    title: entity.title,
                    body: entity.body,
                    sentiment: entity.sentiment,
                    tags: entity.tags?.components(separatedBy: ",").filter { !$0.isEmpty } ?? []
                )
            }
            
            let data = try JSONEncoder().encode(models)
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("anchor_journal_export_\(Date().ISO8601Format()).json")
            try data.write(to: tmp, options: [.atomic])
            
            DispatchQueue.main.async {
                let av = UIActivityViewController(activityItems: [tmp], applicationActivities: nil)
                let presenter = viewController ?? UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }?.rootViewController
                presenter?.present(av, animated: true)
            }
        } catch {
            print("Export failed: \(error)")
        }
    }
}
