//
//  JournalViewModel.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import Foundation
import Combine

final class JournalViewModel: ObservableObject {
    @Published private(set) var entries: [JournalEntry] = []
    private let storageKey = "anchor.journal.entries.v1"
    private var cancellables = Set<AnyCancellable>()

    init() {
        load()
    }

    func load() {
        // Basic local storage via UserDefaults for MVP. Replace with Core Data integration later.
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            do {
                let items = try JSONDecoder().decode([JournalEntry].self, from: data)
                self.entries = items
            } catch {
                Logger.log("Journal decode error: \(error)")
                self.entries = []
            }
        } else {
            self.entries = []
        }
    }

    func saveToDisk() {
        do {
            let data = try JSONEncoder().encode(entries)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            Logger.log("Journal encode error: \(error)")
        }
    }

    func add(entry: JournalEntry) {
        var new = entry
        new.sentiment = AIAnalysisService.shared.analyzeSentiment(text: new.body)
        entries.append(new)
        saveToDisk()
    }

    func update(entry: JournalEntry) {
        if let idx = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[idx] = entry
            entries[idx].sentiment = AIAnalysisService.shared.analyzeSentiment(text: entry.body)
            saveToDisk()
        }
    }

    func delete(at offsets: IndexSet) {
        entries.remove(atOffsets: offsets)
        saveToDisk()
    }

    // Used by export
    func exportableEntries() -> [JournalEntry] {
        return entries
    }
}
