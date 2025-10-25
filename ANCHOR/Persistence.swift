//
//  Persistence.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/8/25.
//

import CoreData
import CloudKit
import os.log

struct PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentCloudKitContainer
    private let logger = Logger(subsystem: "com.yourapp.ANCHOR", category: "Persistence")
    
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
        container = NSPersistentCloudKitContainer(name: "ANCHOR")
        
        // Enable history tracking and remote notifications
        guard let description = container.persistentStoreDescriptions.first else {
            fatalError("###\(#function): Failed to retrieve a persistent store description.")
        }
        
        // Configure for in-memory storage if needed
        if inMemory {
            description.url = URL(fileURLWithPath: "/dev/null")
            description.cloudKitContainerOptions = nil // Disable CloudKit for in-memory stores
        } else {
            // Configure CloudKit
            let cloudKitContainerIdentifier = "iCloud.com.AngadKumar16.ANCHOR"
            let options = NSPersistentCloudKitContainerOptions(containerIdentifier: cloudKitContainerIdentifier)
            description.cloudKitContainerOptions = options
            
            // Enable persistent history tracking
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        // Load the persistent stores
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                self.logger.error("Failed to load persistent stores: \(error), \(error.userInfo)")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        
        // Configure view context
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Set up CloudKit schema and handle remote changes
        if !inMemory {
            do {
                try container.initializeCloudKitSchema(options: [])
                
                // Set up remote change notifications
                NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange, 
                                                    object: container.persistentStoreCoordinator,
                                                    queue: .main) { _ in
                    self.logger.debug("Received a remote store change notification.")
                    // Handle remote changes if needed
                }
                
            } catch {
                logger.error("Failed to initialize CloudKit schema: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - CloudKit Sync
    
    /// Force a sync with CloudKit
    func syncWithCloudKit() async throws {
        try await container.viewContext.perform {
            try self.container.viewContext.save()
            
            // Trigger a sync with CloudKit
            if let store = self.container.persistentStoreCoordinator.persistentStores.first {
                try self.container.persistentStoreCoordinator.setMetadata(
                    [NSPersistentStoreRemoteChangeNotificationPostOptionKey: true], 
                    for: store
                )
            }
        }
    }
    
    /// Reset the local CloudKit data
    func resetCloudKit() async throws {
        try await container.viewContext.perform {
            self.container.viewContext.reset()
            
            // Reset the CloudKit container
            if let store = self.container.persistentStoreCoordinator.persistentStores.first {
                try self.container.persistentStoreCoordinator.remove(store)
                try self.container.persistentStoreCoordinator.addPersistentStore(
                    ofType: NSSQLiteStoreType,
                    configurationName: nil,
                    at: store.url,
                    options: store.options
                )
            }
            
            // Re-fetch data
            try self.container.viewContext.setQueryGenerationFrom(.current)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Save changes to the context if there are any
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                logger.debug("Context saved successfully.")
            } catch {
                let nsError = error as NSError
                logger.error("Unresolved error saving context: \(nsError), \(nsError.userInfo)")
                // Consider presenting an error to the user
            }
        }
    }
}
