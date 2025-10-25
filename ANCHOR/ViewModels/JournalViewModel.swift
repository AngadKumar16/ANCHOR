//
//  JournalViewModel.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//

import Foundation
import CoreData
import Combine

@MainActor
final class JournalViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var entries: [JournalEntry] = []
    @Published var searchText: String = ""
    @Published var selectedTags: Set<String> = []
    @Published private(set) var error: Error?
    
    // MARK: - Private Properties
    private let context: NSManagedObjectContext
    private let undoManager = UndoManager()
    private var cancellables = Set<AnyCancellable>()
    private let pageSize = 20
    private var currentPage = 0
    private var hasMorePages = true
    
    // MARK: - Initialization
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        setupBindings()
        loadMore()
    }
    
    // MARK: - Public Methods
    
    /// Load more entries with pagination
    func loadMore() {
        guard hasMorePages else { return }
        
        Task {
            do {
                let newEntries = try await fetchEntries(page: currentPage, pageSize: pageSize)
                if newEntries.count < pageSize {
                    hasMorePages = false
                }
                if !newEntries.isEmpty {
                    entries.append(contentsOf: newEntries)
                    currentPage += 1
                }
            } catch {
                self.error = error
                Logger.log("Failed to load journal entries: \(error)")
            }
        }
    }
    
    /// Create a new journal entry
    func createEntry(title: String?, body: String, tags: Set<String> = []) async throws {
        var entry = try JournalEntry(
            title: title,
            body: body,
            tags: tags
        )
        
        try entry.validate()
        
        // Analyze sentiment asynchronously
        let sentiment = await analyzeSentiment(text: body)
        entry.sentiment = sentiment
        
        try await saveEntry(entry)
    }
    
    /// Update specific fields of an entry
    func updateEntry(_ entry: JournalEntry, 
                    title: String? = nil, 
                    body: String? = nil, 
                    tags: Set<String>? = nil,
                    isLocked: Bool? = nil) async throws {
        var updatedEntry = entry
        
        if let title = title { updatedEntry.title = title }
        if let body = body { 
            updatedEntry.body = body 
            // Re-analyze sentiment if body changes
            updatedEntry.sentiment = await analyzeSentiment(text: body)
        }
        if let tags = tags { updatedEntry.tags = tags }
        if let isLocked = isLocked { updatedEntry.isLocked = isLocked }
        
        try await saveEntry(updatedEntry)
    }
    
    /// Delete multiple entries
    func delete(entries: [JournalEntry]) async throws {
        let ids = entries.map { $0.id }
        
        try await context.perform {
            let request: NSFetchRequest<NSFetchRequestResult> = JournalEntryEntity.fetchRequest()
            request.predicate = NSPredicate(format: "id IN %@", ids)
            
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            deleteRequest.resultType = .resultTypeObjectIDs
            
            if let result = try self.context.execute(deleteRequest) as? NSBatchDeleteResult,
               let objectIDs = result.result as? [NSManagedObjectID] {
                let changes = [NSDeletedObjectsKey: objectIDs]
                NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.context])
            }
            
            try self.context.save()
            
            // Update local state
            await MainActor.run {
                self.entries.removeAll { ids.contains($0.id) }
            }
        }
    }
    
    // MARK: - Undo/Redo Support
    
    func undo() {
        guard undoManager.canUndo else { return }
        undoManager.undo()
    }
    
    func redo() {
        guard undoManager.canRedo else { return }
        undoManager.redo()
    }
    
    // MARK: - Private Methods
    
    private func setupBindings() {
        $searchText
            .dropFirst()
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
            
        $selectedTags
            .dropFirst()
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }
    
    private func refresh() {
        currentPage = 0
        hasMorePages = true
        entries = []
        loadMore()
    }
    
    private func fetchEntries(page: Int, pageSize: Int) async throws -> [JournalEntry] {
        try await withCheckedThrowingContinuation { continuation in
            context.perform {
                do {
                    let request: NSFetchRequest<JournalEntryEntity> = JournalEntryEntity.fetchRequest()
                    
                    // Build predicate based on search and filters
                    var predicates = [NSPredicate]()
                    
                    if !self.searchText.isEmpty {
                        let searchPredicate = NSPredicate(
                            format: "(title CONTAINS[cd] %@) OR (body CONTAINS[cd] %@)",
                            self.searchText, self.searchText
                        )
                        predicates.append(searchPredicate)
                    }
                    
                    if !self.selectedTags.isEmpty {
                        let tagsPredicate = NSPredicate(
                            format: "ANY tags IN %@", Array(self.selectedTags)
                        )
                        predicates.append(tagsPredicate)
                    }
                    
                    if !predicates.isEmpty {
                        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
                    }
                    
                    // Configure sorting and pagination
                    request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
                    request.fetchLimit = pageSize
                    request.fetchOffset = page * pageSize
                    
                    let results = try self.context.fetch(request)
                    let entries = results.compactMap { $0.toModel() }
                    continuation.resume(returning: entries)
                    
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func saveEntry(_ entry: JournalEntry) async throws {
        try await context.perform {
            let entity = try JournalEntryEntity.updateOrCreate(from: entry, in: self.context)
            try self.context.save()
            
            // Update local state
            await MainActor.run {
                if let index = self.entries.firstIndex(where: { $0.id == entry.id }) {
                    self.entries[index] = entry
                } else {
                    self.entries.insert(entry, at: 0)
                }
            }
        }
    }
    
    private func analyzeSentiment(text: String) async -> Double? {
        // This would call your AIAnalysisService
        // For now, return nil or a mock value
        return nil
    }
}

// MARK: - Preview Support
#if DEBUG
extension JournalViewModel {
    static let preview: JournalViewModel = {
        let vm = JournalViewModel(context: PersistenceController.preview.container.viewContext)
        vm.entries = [.preview]
        return vm
    }()
}
#endif
