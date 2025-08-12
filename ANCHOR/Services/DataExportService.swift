
import Foundation
import UIKit
import SwiftUI

final class DataExportService {
    static let shared = DataExportService()

    private init() {}

    // Export entries as pretty JSON. If you want encryption then don't decrypt here.
    func export(entries: [JournalEntry]) {
        do {
            let data = try JSONEncoder().encode(entries)
            // Write to a temp file and present activityVC
            let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("anchor_export_\(Date().timeIntervalSince1970).json")
            try data.write(to: tmp)
            DispatchQueue.main.async {
                let av = UIActivityViewController(activityItems: [tmp], applicationActivities: nil)
                if let win = UIApplication.shared.windows.first {
                    win.rootViewController?.present(av, animated: true, completion: nil)
                }
            }
        } catch {
            Logger.log("Export failed: \(error)")
        }
    }
}
