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
    
    /// Check if there are more entries to load
    func canLoadMore() -> Bool {
        return hasMorePages
    }
    
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
    
    /// Refresh all entries, resetting pagination
    func refreshEntries() async {
        currentPage = 0
        hasMorePages = true
        entries = []
        loadMore()
    }
    
    /// Fetch journal entries with pagination
    /// - Parameters:
    ///   - page: Page number (0-based)
    ///   - pageSize: Number of items per page
    /// - Returns: Array of JournalEntry
    func fetchEntries(page: Int = 0, pageSize: Int = 20) async throws -> [JournalEntry] {
        try await performOnContext { [weak self] context in
            guard let self = self else { return [] }
            let request = JournalEntryEntity.fetchRequest()
            let offset = page * pageSize
            request.fetchLimit = pageSize
            request.fetchOffset = offset
            request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntryEntity.createdAt, ascending: false)]
            
            // Add search and filter predicates if needed
            var predicates: [NSPredicate] = []
            if !self.searchText.isEmpty {
                predicates.append(NSPredicate(format: "body CONTAINS[cd] %@", self.searchText))
            }
            
            if !self.selectedTags.isEmpty {
                predicates.append(NSPredicate(format: "ANY tags.name IN %@", Array(self.selectedTags)))
            }
            
            if !predicates.isEmpty {
                request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
            }
            
            let entries = try context.fetch(request)
            return entries.compactMap { $0.toModel() }
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
    func updateEntry(_ entry: JournalEntry, title: String? = nil, body: String? = nil, tags: Set<String>? = nil, isLocked: Bool? = nil) async throws {
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
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                do {
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
                    Task { @MainActor in
                        self.entries.removeAll { ids.contains($0.id) }
                        continuation.resume()
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    /// Add a new journal entry
    func add(title: String? = nil, body: String, tags: [String] = []) async throws {
        let entry = try JournalEntry(
            id: UUID(),
            createdAt: Date(),
            title: title,
            body: body,
            bodyFormat: "plain",
            sentiment: nil,
            tags: Set(tags),
            isLocked: false,
            version: 1
        )
        
        try await saveEntry(entry)
        await MainActor.run {
            self.entries.insert(entry, at: 0)
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
    
    private func performOnContext<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await context.perform {
            try block(self.context)
        }
    }
    
    private func saveContext() async throws {
        try await performOnContext { context in
            if context.hasChanges {
                try context.save()
            }
        }
    }
    
    private func saveEntry(_ entry: JournalEntry) async throws {
        try await saveContext()
        try await performOnContext { context in
            _ = try JournalEntryEntity.updateOrCreate(from: entry, in: context)
        }
    }
    
    private func analyzeSentiment(text: String) async -> Double? {
        // Use AIAnalysisService for sentiment analysis
        let service = AIAnalysisService.shared
        let sentiment = service.analyzeSentiment(text: text)
        
        // Convert the Int16 result (-1, 0, 1) to a Double in range -1.0 to 1.0
        return Double(sentiment)
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
