import Foundation
import CoreData
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
        let req: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        req.fetchLimit = 1
        do {
            let arr = try ctx.fetch(req)
            if let first = arr.first {
                profileEntity = first
                displayName = first.displayName ?? ""
            } else {
                // create default
                try ctx.performAndWait {
                    let created = UserProfileEntity.createDefault(in: ctx)
                    try ctx.save()
                    self.profileEntity = created
                    self.displayName = created.displayName ?? ""
                }
            }
            biometricEnabled = UserDefaults.standard.bool(forKey: "anchor.biometricEnabled")
        } catch {
            Logger.log("UserProfile load error: \(error)")
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
