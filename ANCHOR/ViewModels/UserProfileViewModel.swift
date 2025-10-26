import Foundation
import CoreData

@MainActor
class UserProfileViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext
    
    @Published var displayName: String = ""
    @Published var anonymousId: String = ""
    @Published var createdAt: Date = Date()
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        fetchUserProfile()
    }
    
    private func fetchUserProfile() {
        let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            if let profile = results.first {
                displayName = profile.displayName ?? ""
                anonymousId = profile.anonymousId ?? ""
                createdAt = profile.createdAt ?? Date()
            } else {
                // Create a new profile if none exists
                createNewProfile()
            }
        } catch {
            print("Error fetching user profile: \(error)")
            createNewProfile()
        }
    }
    
    private func createNewProfile() {
        let profile = UserProfileEntity.create(
            in: viewContext,
            displayName: nil,
            anonymousId: nil
        )
        
        do {
            try viewContext.save()
            displayName = profile.displayName ?? ""
            anonymousId = profile.anonymousId ?? ""
            createdAt = profile.createdAt ?? Date()
        } catch {
            print("Error creating user profile: \(error)")
            showAlert = true
            alertMessage = "Failed to create user profile"
        }
    }
    
    func updateDisplayName(_ newName: String) {
        let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            if let profile = results.first {
                profile.displayName = newName
                try viewContext.save()
                displayName = newName
                showAlert = true
                alertMessage = "Display name updated successfully"
            }
        } catch {
            print("Error updating display name: \(error)")
            showAlert = true
            alertMessage = "Failed to update display name"
        }
    }
    
    func resetAnonymousId() {
        let newId = UUID().uuidString
        let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            if let profile = results.first {
                profile.anonymousId = newId
                try viewContext.save()
                anonymousId = newId
                showAlert = true
                alertMessage = "Anonymous ID reset successfully"
            }
        } catch {
            print("Error resetting anonymous ID: \(error)")
            showAlert = true
            alertMessage = "Failed to reset anonymous ID"
        }
    }
}
