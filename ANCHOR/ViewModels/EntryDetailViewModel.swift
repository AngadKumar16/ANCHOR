import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class EntryDetailViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var entry: JournalEntry
    @Published private(set) var shouldDismiss = false
    @Published var error: Error?
    
    // MARK: - Private Properties
    private let journalViewModel: JournalViewModel
    private var originalEntry: JournalEntry
    
    // MARK: - Initialization
    init(entry: JournalEntry, journalViewModel: JournalViewModel) {
        self.entry = entry
        self.originalEntry = entry
        self.journalViewModel = journalViewModel
    }
    
    // MARK: - Public Methods
    
    /// Toggle the lock status of the entry
    func toggleLock() {
        var updatedEntry = entry
        updatedEntry.isLocked.toggle()
        
        Task {
            do {
                try await journalViewModel.updateEntry(updatedEntry, isLocked: updatedEntry.isLocked)
                self.entry = updatedEntry
            } catch {
                self.error = error
                Logger.log("Failed to update entry lock status: \(error)")
            }
        }
    }
    
    /// Delete the current entry
    func delete() async {
        do {
            try await journalViewModel.delete(entries: [entry])
            shouldDismiss = true
        } catch {
            self.error = error
            Logger.log("Failed to delete entry: \(error)")
        }
    }
    
    /// Export the entry as a text file
    func export() {
        var content = ""
        
        if let title = entry.title, !title.isEmpty {
            content += "\(title)\n\n"
        }
        
        content += "\(entry.body)\n\n"
        
        // Add metadata
        content += "---\n"
        var formattedDate: String {
            entry.createdAt.formatted(.iso8601)
        }
        content += "Created: \(formattedDate)\n"
        if entry.createdAt != entry.updatedAt {
            content += "Updated: \(entry.updatedAt.formatted(.iso8601))\n"
        }
        if !entry.tags.isEmpty {
            content += "Tags: \(entry.tags.sorted().joined(separator: ", "))\n"
        }
        if let sentiment = entry.sentiment {
            let sentimentString = String(format: "%.1f%%", sentiment * 100)
            content += "Sentiment: \(sentimentString)\n"
        }
        
        // Create a temporary file
        let filename = "Journal Entry - \(formattedDate).txt"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Share the file
            let activityVC = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )
            
            // Present the share sheet
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                activityVC.popoverPresentationController?.sourceView = rootVC.view
                rootVC.present(activityVC, animated: true)
            }
        } catch {
            self.error = error
            Logger.log("Failed to export entry: \(error)")
        }
    }
}

// MARK: - Preview Support

#if DEBUG
extension EntryDetailViewModel {
    static var preview: EntryDetailViewModel {
        EntryDetailViewModel(
            entry: .preview,
            journalViewModel: JournalViewModel(context: PersistenceController.preview.container.viewContext)
        )
    }
}
#endif
