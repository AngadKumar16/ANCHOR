import Foundation
import CoreData
import Combine

@MainActor
final class JournalViewModel: ObservableObject {
    @Published private(set) var entries: [JournalEntry] = []
    @Published var searchText: String = ""
    @Published var selectedTags: Set<String> = []
    @Published private(set) var error: Error?
    @Published private(set) var isLoading: Bool = false

    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    private let pageSize = 20
    private var currentPage = 0
    private var hasMorePages = true

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        setupBindings()
        Task { await loadEntries() }
    }

    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { [weak self] in await self?.refresh() }
            }
            .store(in: &cancellables)
    }

    private func performOnContext<T>(
        _ block: @escaping (NSManagedObjectContext) async throws -> T
    ) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            let bg = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
            bg.parent = self.context
            bg.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            bg.performAndWait {
                do {
                    let result = try await block(bg)
                    if bg.hasChanges {
                        try bg.save()
                        Task { @MainActor in
                            try? self.context.save()
                        }
                    }
                    continuation.resume(returning: result)
                } catch {
                    bg.rollback()
                    continuation.resume(throwing: error)
                }
                }
            }
        }
    }

    private func loadEntries() async {
        do {
            isLoading = true
            let newEntries = try await fetchEntries()
            entries = newEntries
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func canLoadMore() -> Bool { hasMorePages }

    func loadMore() async {
        guard hasMorePages else { return }
        do {
            isLoading = true
            let nextPage = currentPage + 1
            let newEntries = try await fetchEntries(page: nextPage, pageSize: pageSize)
            if newEntries.isEmpty {
                hasMorePages = false
            } else {
                currentPage = nextPage
                entries.append(contentsOf: newEntries)
            }
        } catch {
            self.error = error
        }
        isLoading = false
    }

    func refresh() async {
        currentPage = 0
        hasMorePages = true
        entries = []
        await loadEntries()
    }

    func fetchEntries(page: Int = 0, pageSize: Int = 20) async throws -> [JournalEntry] {
        try await performOnContext<[JournalEntry]> { context in  // ✅ Explicit generic parameter
            let request: NSFetchRequest<JournalEntryEntity> = JournalEntryEntity.fetchRequest()
            request.fetchLimit = pageSize
            request.fetchOffset = page * pageSize
            request.sortDescriptors = [NSSortDescriptor(keyPath: \JournalEntryEntity.createdAt, ascending: false)]
            
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
            
            let objs = try context.fetch(request)
            return try objs.map { try $0.toModel() }
        }
    }

    func createEntry(title: String?, body: String, tags: Set<String> = []) async throws -> JournalEntry {
        let entry = try JournalEntry(
            id: UUID(),
            createdAt: Date(),
            updatedAt: nil,
            title: title,
            body: body,
            bodyFormat: "plain",
            sentiment: await analyzeSentiment(text: body),
            tags: tags,
            isLocked: false,
            version: 1
        )
        return try await saveEntry(entry)
    }

    func updateEntry(_ entry: JournalEntry, title: String? = nil, body: String? = nil, tags: Set<String>? = nil, isLocked: Bool? = nil) async throws -> JournalEntry {
        var e = entry
        if let title = title { e.title = title }
        if let body = body { e.body = body; e.sentiment = await analyzeSentiment(text: body) }
        if let tags = tags { e.tags = tags }
        if let isLocked = isLocked { e.isLocked = isLocked }
        return try await saveEntry(e)
    }

    func delete(entries items: [JournalEntry]) async throws {
        let ids = items.map { $0.id }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                do {
                    let req: NSFetchRequest<NSFetchRequestResult> = JournalEntryEntity.fetchRequest()
                    req.predicate = NSPredicate(format: "id IN %@", ids)
                    let del = NSBatchDeleteRequest(fetchRequest: req)
                    del.resultType = .resultTypeObjectIDs
                    if let result = try self.context.execute(del) as? NSBatchDeleteResult, let oids = result.result as? [NSManagedObjectID] {
                        let changes = [NSDeletedObjectsKey: oids]
                        NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [self.context])
                    }
                    if self.context.hasChanges { try self.context.save() }
                    Task { @MainActor in
                        self.entries.removeAll { ids.contains($0.id) }
                        continuation.resume()
                    }
                } catch { continuation.resume(throwing: error) }
            }
        }
    }

    func add(title: String? = nil, body: String, tags: [String] = []) async throws -> JournalEntry {
        let sentiment = await analyzeSentiment(text: body)
        let entry = try JournalEntry(id: UUID(), createdAt: Date(), title: title, body: body, sentiment: sentiment, tags: Set(tags))
        return try await saveEntry(entry)
    }

    private func saveEntry(_ entry: JournalEntry) async throws -> JournalEntry {
        try await performOnContext<JournalEntry> { context in  // ✅ Explicit generic parameter
            let entity = try JournalEntryEntity.updateOrCreate(from: entry, in: context)
            entity.updatedAt = Date()
            if context.hasChanges { try context.save() }
            return try entity.toModel()
        }
    }


    private func updateLocalEntries(with entry: JournalEntry) {
        if let i = entries.firstIndex(where: { $0.id == entry.id }) { entries[i] = entry } else { entries.insert(entry, at: 0) }
    }

    func refreshEntries() async {
        do {
            let fetched: [JournalEntry] = try await fetchEntries()
            entries = fetched.sorted { $0.createdAt > $1.createdAt }
        } catch { self.error = error }
    }

    private func analyzeSentiment(text: String) async -> Double {
        let positive = ["happy","good","great","awesome","wonderful","amazing"]
        let negative = ["sad","bad","terrible","awful","horrible"]
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines)
        var score = 0
        for w in words { if positive.contains(w) { score += 1 } else if negative.contains(w) { score -= 1 } }
        let normalized = Double(score) / 10.0
        return min(max(normalized, -1.0), 1.0)
    }

    func undo() { context.undo() }

    func redo() { context.redo() }

    func saveContext() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            context.perform {
                do { if self.context.hasChanges { try self.context.save() }; continuation.resume() } catch { continuation.resume(throwing: error) }
            }
        }
    }
}

#if DEBUG
extension JournalViewModel {
    static var preview: JournalViewModel {
        let vm = JournalViewModel(context: PersistenceController.preview.container.viewContext)
        Task { try? await vm.add(title: "Preview Entry", body: "This is a preview journal entry.", tags: ["preview"]) }
        return vm
    }
}
#endif
