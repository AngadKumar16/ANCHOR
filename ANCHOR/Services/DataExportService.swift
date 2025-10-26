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
            
            let models = results.map { entity -> JournalEntryModel in
                return JournalEntryModel(
                    id: entity.id,
                    date: entity.createdAt,
                    title: entity.title,
                    body: entity.body,
                    sentiment: entity.sentiment,
                    tags: entity.tagsArray
                )
            }
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(models)
            
            // Save the file to a temporary location
            let tempDir = FileManager.default.temporaryDirectory
            let fileName = "journal_export_\(Date().timeIntervalSince1970).json"
            let fileURL = tempDir.appendingPathComponent(fileName)
            
            try data.write(to: fileURL)
            
            // Present share sheet
            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(
                    activityItems: [fileURL],
                    applicationActivities: nil
                )
                
                if let vc = viewController {
                    activityVC.popoverPresentationController?.sourceView = vc.view
                    vc.present(activityVC, animated: true)
                }
            }
            
        } catch {
            print("Error exporting journal entries: \(error)")
        }
    }
}
