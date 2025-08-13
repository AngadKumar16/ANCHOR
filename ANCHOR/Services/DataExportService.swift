import Foundation
import UIKit
import CoreData

final class DataExportService {
    static let shared = DataExportService()
    private init() {}

    func exportAllJournalEntries(presenting viewController: UIViewController?) {
        let ctx = PersistenceController.shared.container.viewContext
        let req: NSFetchRequest<JournalEntryEntity> = JournalEntryEntity.fetchRequest()
        do {
            let results = try ctx.fetch(req)
            // decrypt to plain structs
            let models = results.map { $0.toModel() }
            let data = try JSONEncoder().encode(models)
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("anchor_journal_export.json")
            try data.write(to: tmp, options: .atomicWrite)
            DispatchQueue.main.async {
                let av = UIActivityViewController(activityItems: [tmp], applicationActivities: nil)
                let presenter = viewController ?? UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }?.rootViewController
                presenter?.present(av, animated: true)
            }
        } catch {
            Logger.log("Export failed: \(error)")
        }
    }
}
