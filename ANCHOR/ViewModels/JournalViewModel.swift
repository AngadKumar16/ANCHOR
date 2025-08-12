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
    @Published var entries: [JournalEntryModel] = []
    private let ctx: NSManagedObjectContext

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.ctx = context
        Task { await load() }
    }

    func load() async {
        let req: NSFetchRequest<JournalEntryEntity> = JournalEntryEntity.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        do {
            let results = try ctx.fetch(req)
            self.entries = results.map { $0.toModel() }
        } catch {
            Logger.log("Journal load error: \(error)")
            self.entries = []
        }
    }

    func add(title: String?, body: String, tags: [String]) async throws {
        try Task.checkCancellation()
        try ctx.performAndWait {
            let csv = tags.joined(separator: ",")
            let entity = try JournalEntryEntity.create(in: ctx, title: title, bodyPlain: body, tagsCSV: csv)
            entity.sentiment = AIAnalysisService.shared.analyzeSentiment(text: body)
            try ctx.save()
        }
        await load()
    }

    func update(entryId: UUID, newTitle: String?, newBody: String, newTags: [String]) async throws {
        try Task.checkCancellation()
        try ctx.performAndWait {
            let req: NSFetchRequest<JournalEntryEntity> = JournalEntryEntity.fetchRequest()
            req.predicate = NSPredicate(format: "id == %@", entryId as CVarArg)
            req.fetchLimit = 1
            if let found = try ctx.fetch(req).first {
                found.title = newTitle
                found.updateBody(newBody)
                found.tags = newTags.joined(separator: ",")
                found.sentiment = AIAnalysisService.shared.analyzeSentiment(text: newBody)
                try ctx.save()
            }
        }
        await load()
    }

    func delete(at offsets: IndexSet) async {
        try? await ctx.perform {
            // map offsets to current entries
            let ids = offsets.map { self.entries[$0].id }
            let req: NSFetchRequest<JournalEntryEntity> = JournalEntryEntity.fetchRequest()
            req.predicate = NSPredicate(format: "id IN %@", ids)
            let results = try ctx.fetch(req)
            for r in results { ctx.delete(r) }
            try ctx.save()
        }
        await load()
    }
}
