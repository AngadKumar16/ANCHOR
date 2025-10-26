//
//  Persistence.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/8/25.
//

import CoreData
import os.log
import Combine

final class PersistenceController: ObservableObject {
    static let shared = PersistenceController()
    let container: NSPersistentCloudKitContainer
    private let logger = OSLog(subsystem: "com.angadkumar16.ANCHOR", category: "Persistence")
    
    // Published property to track changes
    @Published var viewContext: NSManagedObjectContext
    
    @MainActor
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let viewContext = controller.container.viewContext
        
        // Add preview data
        for i in 0..<10 {
            let entry = JournalEntryEntity(context: viewContext)
            entry.id = UUID()
            entry.title = "Preview Entry \(i+1)"
            entry.body = "This is a preview journal entry number \(i+1)."
            entry.createdAt = Date()
            entry.updatedAt = Date()
            entry.isLocked = i % 3 == 0
        }
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return controller
    }()
    
    init(inMemory: Bool = false) {
        os_log("🔄 Initializing PersistenceController (inMemory: %@)", 
              log: logger, 
              type: .debug, 
              inMemory ? "true" : "false")
        
        container = NSPersistentCloudKitContainer(name: "ANCHOR")
        
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
            os_log("📦 Using in-memory store", log: logger, type: .debug)
        }
        
        // Enable history tracking and remote notifications
        guard let description = container.persistentStoreDescriptions.first else {
            os_log("❌ Failed to retrieve a persistent store description", log: logger, type: .error)
            fatalError("Failed to retrieve a persistent store description.")
        }
        
        description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        // Store logger in a local variable to avoid capturing self
        let logger = self.logger
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                os_log("❌ Failed to load persistent store: %{public}@", 
                      log: logger, 
                      type: .error, 
                      error.localizedDescription)
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                os_log("✅ Successfully loaded persistent store: %{public}@", 
                      log: logger, 
                      type: .info, 
                      description.description)
            }
        }
        
        // Configure view context
        viewContext = container.viewContext
        viewContext.automaticallyMergesChangesFromParent = true
        viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        // Set up CloudKit schema if needed
        #if DEBUG
        do {
            try container.initializeCloudKitSchema()
            os_log("Successfully initialized CloudKit schema", log: logger, type: .debug)
        } catch {
            os_log("Failed to initialize CloudKit schema: %{public}@", log: logger, type: .error, error.localizedDescription)
        }
        #endif
    }
    
    // MARK: - Core Data Saving support
    
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                os_log("Context saved successfully.", log: logger, type: .debug)
            } catch {
                let nsError = error as NSError
                os_log("Unresolved error saving context: %{public}@", log: logger, type: .error, nsError.localizedDescription)
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    // MARK: - CloudKit Sync
    
    @discardableResult
    func saveIfNeeded() -> Bool {
        let context = container.viewContext
        guard context.hasChanges else { return false }
        
        do {
            try context.save()
            return true
        } catch {
            context.rollback()
            return false
        }
    }
    
    /// Reset the local CloudKit data
    func resetCloudKit() async throws {
        try await container.viewContext.perform { [weak self] in
            guard let self = self else { return }
            
            // Delete all data from all entities
            let entities = self.container.managedObjectModel.entities
            for entity in entities {
                if let entityName = entity.name {
                    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
                    let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                    
                    do {
                        try self.container.viewContext.execute(deleteRequest)
                    } catch {
                        throw error
                    }
                }
            }
            
            // Save the context
            try self.container.viewContext.save()
            os_log("Reset local CloudKit data", log: self.logger, type: .info)
        }
    }
}
