//
//  Persistence.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/8/25.
//

import CoreData
import os.log

// Changed from struct to class to handle escaping closures properly
final class PersistenceController {
    static let shared = PersistenceController()
    let container: NSPersistentCloudKitContainer
    private let logger = OSLog(subsystem: "com.angadkumar16.ANCHOR", category: "Persistence")
    
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
            os_log("Failed to save preview data: %{public}@", log: controller.logger, type: .error, nsError.localizedDescription)
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return controller
    }()
    
    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "ANCHOR")
        
        // Enable history tracking and remote notifications
        guard let description = container.persistentStoreDescriptions.first else {
            os_log("Failed to retrieve a persistent store description", log: logger, type: .error)
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
        container.loadPersistentStores { [weak self] storeDescription, error in
            if let error = error as NSError? {
                os_log("Failed to load persistent stores: %{public}@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            if let url = storeDescription.url {
                os_log("Successfully loaded persistent store at %{public}@", log: self?.logger ?? .default, type: .info, url.absoluteString)
            } else {
                os_log("Successfully loaded persistent store", log: self?.logger ?? .default, type: .info)
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
                os_log("Successfully initialized CloudKit schema", log: logger, type: .debug)
                
                // Set up remote change notifications
                NotificationCenter.default.addObserver(forName: .NSPersistentStoreRemoteChange, 
                                                    object: container.persistentStoreCoordinator,
                                                    queue: .main) { [weak self] _ in
                    guard let self = self else { return }
                    os_log("Received a remote store change notification", log: self.logger, type: .debug)
                    // Handle remote changes if needed
                }
                
            } catch {
                os_log("Failed to initialize CloudKit schema: %{public}@", log: logger, type: .error, error.localizedDescription)
            }
        }
    }
    
    // MARK: - CloudKit Sync
    
    /// Force a sync with CloudKit
    func syncWithCloudKit() async throws {
        try await container.viewContext.perform { [weak self] in
            guard let self = self else { return }
            
            do {
                try self.container.viewContext.save()
                os_log("Successfully saved context for CloudKit sync", log: self.logger, type: .debug)
                
                // Trigger a sync with CloudKit
                if let store = self.container.persistentStoreCoordinator.persistentStores.first {
                    try self.container.persistentStoreCoordinator.setMetadata(
                        [NSPersistentStoreRemoteChangeNotificationPostOptionKey: true], 
                        for: store
                    )
                    os_log("Successfully triggered CloudKit sync", log: self.logger, type: .debug)
                }
            } catch {
                os_log("Failed to sync with CloudKit: %{public}@", log: self.logger, type: .error, error.localizedDescription)
                throw error
            }
        }
    }
    
    /// Reset the local CloudKit data
    func resetCloudKit() async throws {
        try await container.viewContext.perform { [weak self] in
            guard let self = self else { return }
            
            self.container.viewContext.reset()
            os_log("Reset local CloudKit data", log: self.logger, type: .info)
            
            // Reset the CloudKit container
            if let store = self.container.persistentStoreCoordinator.persistentStores.first {
                try? self.container.persistentStoreCoordinator.setMetadata(
                    [NSPersistentStoreRemoteChangeNotificationPostOptionKey: true],
                    for: store
                )
            }
        }
    }
    
    // MARK: - Core Data Saving support
    
    func saveContext() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
                os_log("Context saved successfully.", log: logger, type: .debug)
            } catch {
                os_log("Unresolved error saving context: %{public}@", log: logger, type: .error, error.localizedDescription)
                // Consider presenting an error to the user
            }
        }
    }
}
