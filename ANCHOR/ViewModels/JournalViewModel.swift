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
    @Published private(set) var isLoading: Bool = false
    
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
        Task {
            await loadEntries()
        }
    }
    
    // MARK: - Public Methods
    
    /// Check if there are more entries to load
    func canLoadMore() -> Bool {
        return hasMorePages
    }
    
    /// Load more entries with pagination
    @MainActor
    func loadMore() async {
        guard hasMorePages else { return }
        
        do {
            isLoading = true
            let currentPage = entries.count / pageSize
            let newEntries = try await fetchEntries(page: currentPage, pageSize: pageSize)
            if newEntries.isEmpty {
                hasMorePages = false
            } else {
                entries.append(contentsOf: newEntries)
            }
        } catch {
            self.error = error
            print("❌ Failed to load more entries: \(error)")
        }
        
        isLoading = false
    }
    
    /// Refresh all entries, resetting pagination
    func refresh() async {
        currentPage = 0
        hasMorePages = true
        entries = []
        await loadEntries()
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
            return try entries.compactMap { entity in
                try entity.toModel()
            }
        }
    }
    
    /// Create a new journal entry
    func createEntry(title: String?, body: String, tags: Set<String> = []) async throws {
        // Create a new journal entry with the provided parameters
        // Using the full initializer to ensure all required parameters are provided
        let entry: JournalEntry
        do {
            entry = try JournalEntry(
                id: UUID(),
                createdAt: Date(),
                updatedAt: nil,
                title: title,
                body: body,
                bodyFormat: "plain",
                sentiment: nil,
                tags: tags,
                isLocked: false,
                version: 1
            )
        } catch {
            throw error
        }
        
        // Analyze sentiment asynchronously
        let sentiment = await analyzeSentiment(text: body)
        var updatedEntry = entry
        updatedEntry.sentiment = sentiment
        
        try await saveEntry(updatedEntry)
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
    
    // MARK: - Journal Entry Management
    func add(title: String? = nil, body: String, tags: [String] = []) async throws -> JournalEntry {
        let entry = try JournalEntry(
            id: UUID(),
            createdAt: Date(),
            updatedAt: nil,
            title: title,
            body: body,
            bodyFormat: "plain",
            sentiment: await analyzeSentiment(text: body),
            tags: Set(tags),
            isLocked: false,
            version: 1
        )
        return try await saveEntry(entry)
    }

    private func saveEntry(_ entry: JournalEntry) async throws -> JournalEntry {
        let savedEntry = try await performOnContext { context -> JournalEntry in
            let entity = try JournalEntryEntity.updateOrCreate(from: entry, in: context)
            entity.updatedAt = Date()
            
            if context.hasChanges {
                try context.save()
            }
            
            return try entity.toModel()
        }
        
        await updateLocalEntries(with: savedEntry)
        return savedEntry
    }

    @MainActor
    private func updateLocalEntries(with entry: JournalEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
        } else {
            entries.insert(entry, at: 0)
        }
    }

    @MainActor
    func refreshEntries() async {
        do {
            let fetchedEntries = try await fetchEntries()
            entries = fetchedEntries.sorted { $0.createdAt > $1.createdAt }
        } catch {
            print("❌ Failed to refresh entries: \(error)")
            self.error = error
        }
    }

    // MARK: - Core Data Operations
    private func performOnContext<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            let context = PersistenceController.shared.container.newBackgroundContext()
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            context.automaticallyMergesChangesFromParent = true
            
            context.perform {
                do {
                    let result = try block(context)
                    continuation.resume(returning: result)
                } catch {
                    context.rollback()
                    print("❌ Error in performOnContext: \(error)")
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func fetchEntries() async throws -> [JournalEntry] {
        try await performOnContext { context in
            let request = JournalEntryEntity.fetchRequest()
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
            
            let entities = try context.fetch(request)
            return try entities.map { try $0.toModel() }
        }
    }

    // MARK: - Sentiment Analysis
    private func analyzeSentiment(text: String) async -> Double? {
        let service = AIAnalysisService.shared
        let sentiment = service.analyzeSentiment(text: text)
        return Double(sentiment.rawValue)
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
            .combineLatest($selectedTags)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Task { @MainActor in
                    await self.refresh()
                }
            }
            .store(in: &cancellables)
    }
    
    private func saveContext() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                do {
                    if self.context.hasChanges {
                        try self.context.save()
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    // MARK: - Data Loading
    @MainActor
    func loadEntries() async {
        do {
            let request: NSFetchRequest<JournalEntryEntity> = JournalEntryEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntryEntity.createdAt, ascending: false)]
            
            print("🔄 Loading journal entries...")
            let entities = try context.fetch(request)
            print("✅ Found \(entities.count) journal entries")
            
            let entries = try entities.compactMap { entity in
                try entity.toModel()
            }
            
            self.entries = entries
            print("📊 Loaded \(self.entries.count) valid journal entries")
        } catch {
            print("❌ Failed to fetch journal entries: \(error)")
            self.error = error
        }
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
