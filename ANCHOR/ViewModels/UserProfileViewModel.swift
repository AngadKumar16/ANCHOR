import Foundation
import CoreData
import LocalAuthentication

@MainActor
class UserProfileViewModel: ObservableObject {
    private let viewContext: NSManagedObjectContext
    private let biometricAuth = LAContext()
    
    @Published var displayName: String = "" {
        didSet {
            updateProfile(displayName: displayName)
        }
    }
    
    @Published var anonymousId: String = ""
    @Published var createdAt: Date = Date()
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var biometricEnabled: Bool = false
    
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
                biometricEnabled = profile.biometricEnabled
            } else {
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
            anonymousId: nil,
            biometricEnabled: false
        )
        
        do {
            try viewContext.save()
            displayName = profile.displayName ?? ""
            anonymousId = profile.anonymousId ?? ""
            createdAt = profile.createdAt ?? Date()
            biometricEnabled = profile.biometricEnabled
        } catch {
            print("Error creating user profile: \(error)")
        }
    }
    
    func updateDisplayName(_ name: String) {
        displayName = name
    }
    
    func updateBiometricEnabled(_ enabled: Bool) {
        biometricEnabled = enabled
        updateProfile(biometricEnabled: enabled)
    }
    
    private func updateProfile(displayName: String? = nil, biometricEnabled: Bool? = nil) {
        let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        request.fetchLimit = 1
        
        do {
            let results = try viewContext.fetch(request)
            if let profile = results.first {
                if let displayName = displayName {
                    profile.displayName = displayName
                }
                if let enabled = biometricEnabled {
                    profile.biometricEnabled = enabled
                }
                try viewContext.save()
            }
        } catch {
            print("Error updating user profile: \(error)")
            alertMessage = "Failed to update profile: \(error.localizedDescription)"
            showAlert = true
        }
    }
    
    var biometricType: LABiometryType {
        var error: NSError?
        if biometricAuth.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return biometricAuth.biometryType
        }
        return .none
    }
    
    var biometricIconName: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock"
        }
    }
}
