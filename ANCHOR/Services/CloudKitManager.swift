import CloudKit
import os.log

/// Manages CloudKit operations for the app
@MainActor
final class CloudKitManager: ObservableObject {
    // MARK: - Properties
    
    static let shared = CloudKitManager()
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let logger = Logger(subsystem: "com.yourapp.ANCHOR", category: "CloudKit")
    
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    @Published var hasCloudKitError: Bool = false
    @Published var lastSyncDate: Date?
    
    // MARK: - Initialization
    
    private init() {
        self.container = CKContainer(identifier: "iCloud.com.AngadKumar16.ANCHOR")
        self.privateDatabase = container.privateCloudDatabase
        
        // Set up account status observation
        Task {
            await checkAccountStatus()
            await fetchLastSyncDate()
        }
        
        // Set up subscription for remote changes
        setupSubscriptions()
    }
    
    // MARK: - Account Status
    
    /// Checks the current iCloud account status
    func checkAccountStatus() async {
        do {
            let status = try await container.accountStatus()
            await MainActor.run {
                self.accountStatus = status
                self.hasCloudKitError = (status != .available)
                
                if status != .available {
                    logger.warning("iCloud account status: \(status.rawValue)")
                }
            }
            
            if status == .available {
                // Ensure the user is logged into iCloud and has the required permissions
                try await container.requestApplicationPermission(.userDiscoverability)
            }
        } catch {
            await MainActor.run {
                self.hasCloudKitError = true
                self.logger.error("Failed to check iCloud account status: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Record Operations
    
    /// Fetches the last sync date from CloudKit
    private func fetchLastSyncDate() async {
        let query = CKQuery(recordType: "LastSync", predicate: NSPredicate(value: true))
        
        do {
            let records = try await privateDatabase.records(matching: query)
            if let record = records.matchResults.first?.1.get() {
                let lastSync = try record.decoded(as: LastSync.self)
                await MainActor.run {
                    self.lastSyncDate = lastSync.date
                }
            }
        } catch {
            logger.error("Failed to fetch last sync date: \(error.localizedDescription)")
        }
    }
    
    /// Updates the last sync date in CloudKit
    func updateLastSyncDate() async {
        let recordID = CKRecord.ID(recordName: "last-sync")
        let lastSync = LastSync(date: Date())
        
        do {
            let record = try CKRecord(encodable: lastSync)
            record.recordID = recordID
            
            _ = try await privateDatabase.save(record)
            await MainActor.run {
                self.lastSyncDate = lastSync.date
            }
        } catch {
            logger.error("Failed to update last sync date: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Subscriptions
    
    /// Sets up subscriptions for CloudKit changes
    private func setupSubscriptions() {
        // Check if subscription already exists
        let subscriptionID = "journal-changes"
        
        Task {
            do {
                let subscriptions = try await privateDatabase.allSubscriptions()
                if subscriptions.contains(where: { $0.subscriptionID == subscriptionID }) {
                    return
                }
                
                // Create a subscription for changes to JournalEntry records
                let predicate = NSPredicate(value: true)
                let subscription = CKQuerySubscription(
                    recordType: "JournalEntry",
                    predicate: predicate,
                    subscriptionID: subscriptionID,
                    options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
                )
                
                let notification = CKSubscription.NotificationInfo()
                notification.shouldSendContentAvailable = true
                subscription.notificationInfo = notification
                
                _ = try await privateDatabase.save(subscription)
                logger.info("Successfully set up CloudKit subscription")
                
            } catch {
                logger.error("Failed to set up CloudKit subscription: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Manual Sync
    
    /// Performs a manual sync with CloudKit
    func manualSync() async -> Bool {
        do {
            try await checkAccountStatus()
            guard accountStatus == .available else {
                logger.error("Cannot sync: iCloud account not available")
                return false
            }
            
            // Perform any additional sync operations here
            await updateLastSyncDate()
            return true
            
        } catch {
            logger.error("Manual sync failed: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - Supporting Types

/// Represents the last sync information stored in CloudKit
private struct LastSync: Codable {
    let date: Date
    
    enum CodingKeys: String, CodingKey {
        case date = "lastSyncDate"
    }
}

// MARK: - CKRecord Encoding/Decoding

extension CKRecord {
    /// Creates a CKRecord from an Encodable object
    convenience init(encodable: Encodable) throws {
        let data = try JSONEncoder().encode(encodable)
        let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        
        let recordType = String(describing: type(of: encodable))
        self.init(recordType: recordType)
        
        for (key, value) in dictionary {
            self[key] = value as? CKRecordValue
        }
    }
}

extension CKRecord {
    /// Decodes a CKRecord into a Decodable object
    func decoded<T: Decodable>(as type: T.Type) throws -> T {
        let dictionary = allKeys().reduce(into: [String: Any]()) { result, key in
            result[key] = self[key]
        }
        
        let data = try JSONSerialization.data(withJSONObject: dictionary)
        return try JSONDecoder().decode(type, from: data)
    }
}

// MARK: - Preview Support

#if DEBUG
extension CloudKitManager {
    static var preview: CloudKitManager {
        let manager = CloudKitManager()
        manager.accountStatus = .available
        manager.lastSyncDate = Date()
        return manager
    }
}
#endif
