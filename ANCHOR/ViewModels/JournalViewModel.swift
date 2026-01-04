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
    var hasMorePages = true

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        setupBindings()
        Task { await refresh() }
    }

    private func setupBindings() {
        $searchText
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                Task { await self?.refresh() }
            }
            .store(in: &cancellables)
    }

    func refresh() async {
        guard !isLoading else { return }
        currentPage = 0
        hasMorePages = true
        await loadEntries(isRefresh: true)
    }

    private func performOnContext<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let bgContext = context.newBackgroundContext()
        return try await bgContext.perform {
            let result = try block(bgContext)
            if bgContext.hasChanges {
                try bgContext.save()
            }
            return result
        }
    }

    private func loadEntries(isRefresh: Bool = false) async {
        if isRefresh {
            isLoading = true
        } else if !hasMorePages {
            return
        }
        
        defer { 
            if isRefresh { isLoading = false } 
        }

        do {
            let newEntries = try await fetchEntries()
            if isRefresh {
                entries = newEntries
            } else {
                entries.append(contentsOf: newEntries)
            }
        } catch {
            self.error = error
        }
    }

    func loadMoreIfNeeded(currentItem item: JournalEntry?) async {
        guard let item = item else {
            await loadMore()
            return
        }

        let thresholdIndex = entries.index(entries.endIndex, offsetBy: -5)
        if entries.firstIndex(where: { $0.id == item.id }) == thresholdIndex {
            await loadMore()
        }
    }

    func loadMore() async {
        guard hasMorePages, !isLoading else { return }
        await loadEntries()
    }

    private func fetchEntries() async throws -> [JournalEntry] {
        let request = JournalEntryEntity.fetchRequest()
        var predicates: [NSPredicate] = []

        if !searchText.isEmpty {
            predicates.append(NSPredicate(format: "title CONTAINS[c] %@ OR body CONTAINS[c] %@", searchText, searchText))
        }

        if !selectedTags.isEmpty {
            predicates.append(NSPredicate(format: "ANY tags.name IN %@", selectedTags))
        }

        request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        request.fetchOffset = currentPage * pageSize
        request.fetchLimit = pageSize

        let results = try await performOnContext { context in
            try context.fetch(request).compactMap { try $0.toModel() }
        }

        if results.count < pageSize {
            hasMorePages = false
        }
        currentPage += 1

        return results
    }

    func updateEntry(_ entry: JournalEntry) async {
        do {
            try await performOnContext { context in
                _ = try JournalEntryEntity.updateOrCreate(from: entry, in: context)
            }
            await refresh()
        } catch {
            self.error = error
        }
    }

    func createEntry(title: String?, body: String, tags: Set<String>) async throws {
        let newEntry = try JournalEntry(title: title, body: body, tags: tags)
        try await performOnContext { context in
            _ = try JournalEntryEntity.updateOrCreate(from: newEntry, in: context)
        }
    }

    func updateEntry(_ entry: JournalEntry, title: String?, body: String, tags: Set<String>) async throws {
        let updatedEntry = try entry.withUpdatedContent(title: title, body: body)
        try await performOnContext { context in
            _ = try JournalEntryEntity.updateOrCreate(from: updatedEntry, in: context)
        }
    }

    func add(title: String, body: String, tags: [String]) async {
        do {
            let newEntry = try JournalEntry(title: title, body: body, tags: Set(tags))
            try await performOnContext { context in
                _ = try JournalEntryEntity.updateOrCreate(from: newEntry, in: context)
            }
            await refresh()
        } catch {
            self.error = error
        }
    }

    func delete(entries items: [JournalEntry]) async throws {
        let ids = items.map { $0.id }
        try await performOnContext { context in
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = JournalEntryEntity.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "id IN %@", ids as CVarArg)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            try context.execute(deleteRequest)
        }
        await refresh()
    }
}

#if DEBUG
extension JournalViewModel {
    static var preview: JournalViewModel {
        let vm = JournalViewModel(context: PersistenceController.preview.container.viewContext)
        return vm
    }
}
#endif

public extension NSManagedObjectContext {
    func newBackgroundContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = self
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return context
    }
}
