import SwiftUI
import CloudKit
import os.log

@MainActor
final class CloudSyncSettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var isSyncEnabled: Bool = false {
        didSet {
            if isSyncEnabled {
                Task { await checkCloudKitAvailability() }
            }
            saveSettings()
        }
    }
    
    @Published var wiFiOnly: Bool = true {
        didSet { saveSettings() }
    }
    
    @Published var includeAttachments: Bool = true {
        didSet { saveSettings() }
    }
    
    @Published var lastSyncDate: Date? = nil
    @Published var showResetConfirmation: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var accountStatus: CKAccountStatus = .couldNotDetermine
    
    // MARK: - Private Properties
    private let cloudKitManager = CloudKitManager.shared
    private let logger = Logger(subsystem: "com.yourapp.ANCHOR", category: "CloudSync")
    
    // MARK: - Initialization
    init() {
        loadSettings()
        setupObservers()
    }
    
    // MARK: - Public Methods
    
    /// Loads the current sync settings
    func loadSettings() {
        isLoading = true
        defer { isLoading = false }
        
        // Load from UserDefaults
        let defaults = UserDefaults.standard
        isSyncEnabled = defaults.bool(forKey: "isCloudSyncEnabled")
        wiFiOnly = defaults.bool(forKey: "wifiOnlySync")
        includeAttachments = defaults.bool(forKey: "includeAttachmentsInSync")
        
        // Update last sync date from CloudKit
        Task {
            await updateSyncStatus()
        }
    }
    
    /// Saves the current settings to UserDefaults
    func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(isSyncEnabled, forKey: "isCloudSyncEnabled")
        defaults.set(wiFiOnly, forKey: "wifiOnlySync")
        defaults.set(includeAttachments, forKey: "includeAttachmentsInSync")
        
        // If enabling sync, check CloudKit availability
        if isSyncEnabled {
            Task {
                await checkCloudKitAvailability()
            }
        }
    }
    
    /// Performs a manual sync with CloudKit
    func manualSync() async {
        guard isSyncEnabled else { 
            errorMessage = "Cloud sync is disabled"
            return 
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let success = await cloudKitManager.manualSync()
            if success {
                await updateSyncStatus()
            } else {
                errorMessage = "Failed to sync with iCloud. Please check your internet connection and iCloud settings."
            }
        }
        
        isLoading = false
    }
    
    /// Resets all sync data
    func resetSyncData() async {
        guard isSyncEnabled else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // In a real app, you would handle the actual CloudKit reset here
            // This is a simplified version that just resets the local state
            try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
            
            // Reset to default values
            wiFiOnly = true
            includeAttachments = true
            lastSyncDate = nil
            
            // Save the reset state
            let defaults = UserDefaults.standard
            defaults.removeObject(forKey: "lastCloudSyncDate")
            saveSettings()
            
            // Update the UI
            await updateSyncStatus()
            
        } catch {
            errorMessage = "Failed to reset sync data: \(error.localizedDescription)"
            logger.error("\(error.localizedDescription)")
        }
        
        isLoading = false
        showResetConfirmation = false
    }
    
    // MARK: - Private Methods
    
    /// Sets up observers for CloudKit account changes
    private func setupObservers() {
        // Listen for account status changes
        NotificationCenter.default.addObserver(
            forName: .CKAccountChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.logger.debug("iCloud account status changed")
            Task { [weak self] in
                await self?.checkCloudKitAvailability()
            }
        }
    }
    
    /// Checks CloudKit availability and updates the UI accordingly
    private func checkCloudKitAvailability() async {
        await updateAccountStatus()
        
        if accountStatus != .available {
            errorMessage = "iCloud is not available. Please sign in to iCloud in Settings."
            isSyncEnabled = false
            return
        }
        
        // If we got here, CloudKit is available
        await updateSyncStatus()
    }
    
    /// Updates the account status from CloudKit
    private func updateAccountStatus() async {
        await cloudKitManager.checkAccountStatus()
        accountStatus = cloudKitManager.accountStatus
        
        if cloudKitManager.hasCloudKitError {
            errorMessage = "Error accessing iCloud. Please check your internet connection and iCloud settings."
        }
    }
    
    /// Updates the last sync date from CloudKit
    private func updateSyncStatus() async {
        lastSyncDate = cloudKitManager.lastSyncDate
    }
}

// MARK: - Preview Support

#if DEBUG
extension CloudSyncSettingsViewModel {
    static var preview: CloudSyncSettingsViewModel {
        let viewModel = CloudSyncSettingsViewModel()
        viewModel.isSyncEnabled = true
        viewModel.lastSyncDate = Date()
        return viewModel
    }
}
#endif
