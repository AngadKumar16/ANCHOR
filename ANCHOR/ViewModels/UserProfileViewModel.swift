@preconcurrency import CoreData
import Foundation
import LocalAuthentication

@MainActor
final class UserProfileViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var biometricEnabled: Bool = false

    private let ctx: NSManagedObjectContext
    private var profileEntity: UserProfileEntity?

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.ctx = context
        load()
    }

    func load() {
        Task {
            do {
                let fetchRequest = NSFetchRequest<UserProfileEntity>(entityName: "UserProfileEntity")
                fetchRequest.fetchLimit = 1
                
                let arr = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[UserProfileEntity], Error>) in
                    ctx.perform {
                        do {
                            let result = try self.ctx.fetch(fetchRequest)
                            continuation.resume(returning: result)
                        } catch {
                            continuation.resume(throwing: error)
                        }
                    }
                }
                
                if let first = arr.first {
                    await MainActor.run {
                        self.profileEntity = first
                        self.displayName = first.displayName ?? ""
                    }
                } else {
                    // create default
                    let created = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<UserProfileEntity, Error>) in
                        ctx.perform {
                            do {
                                let created = UserProfileEntity.createDefault(in: self.ctx)
                                try self.ctx.save()
                                continuation.resume(returning: created)
                            } catch {
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                    
                    await MainActor.run {
                        self.profileEntity = created
                        self.displayName = created.displayName ?? ""
                    }
                }
                
                let isBiometricEnabled = UserDefaults.standard.bool(forKey: "anchor.biometricEnabled")
                await MainActor.run {
                    self.biometricEnabled = isBiometricEnabled
                }
                
            } catch {
                Logger.log("UserProfile load error: \(error)")
            }
        }
    }

    func save() {
        guard let pe = profileEntity else { return }
        pe.displayName = displayName
        do {
            try ctx.save()
        } catch {
            Logger.log("Profile save err: \(error)")
        }
    }

    func toggleBiometric(_ enable: Bool, completion: @escaping (Bool)->Void) {
        let ctxLA = LAContext()
        var err: NSError?
        if ctxLA.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) {
            ctxLA.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Enable biometric unlock for ANCHOR") { success, _ in
                DispatchQueue.main.async {
                    if success {
                        self.biometricEnabled = enable
                        UserDefaults.standard.set(enable, forKey: "anchor.biometricEnabled")
                    }
                    completion(success)
                }
            }
        } else {
            completion(false)
        }
    }
}
