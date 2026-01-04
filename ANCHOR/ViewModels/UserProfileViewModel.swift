import Foundation
import CoreData
import LocalAuthentication
import Combine

@MainActor
final class UserProfileViewModel: ObservableObject {
    private let context: NSManagedObjectContext
    private let biometricAuth = LAContext()
    private var cancellables = Set<AnyCancellable>()

    @Published var displayName: String = ""
    @Published var anonymousId: String = ""
    @Published var createdAt: Date = Date()
    @Published var showAlert = false
    @Published var alertMessage = ""
    @Published var biometricEnabled: Bool = false

    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        self.context = context
        Task { await fetchUserProfile() }
        setupSubscribers()
    }

    private func setupSubscribers() {
        $displayName
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] name in
                self?.updateProfile(displayName: name)
            }
            .store(in: &cancellables)

        $biometricEnabled
            .dropFirst()
            .sink { [weak self] enabled in
                self?.updateProfile(biometricEnabled: enabled)
            }
            .store(in: &cancellables)
    }

    private func performOnContext<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        let bgContext = context.newBackgroundContext()
        return try await bgContext.perform {
            let result = try block(bgContext)
            if bgContext.hasChanges {
                try bgContext.save()
            }
            return result
        }
    }

    private func fetchUserProfile() async {
        do {
            let profiles: [UserProfileEntity] = try await performOnContext { context in
                let request = UserProfileEntity.fetchRequest()
                request.fetchLimit = 1
                return try context.fetch(request)
            }

            if let profile = profiles.first {
                displayName = profile.displayName ?? ""
                anonymousId = profile.anonymousId ?? ""
                createdAt = profile.createdAt ?? Date()
                biometricEnabled = profile.biometricEnabled
            } else {
                await createNewProfile()
            }
        } catch {
            alertMessage = "Failed to fetch profile: \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func createNewProfile() async {
        do {
            let profile: UserProfileEntity = try await performOnContext { context in
                let newProfile = UserProfileEntity(context: context)
                newProfile.anonymousId = UUID().uuidString
                newProfile.createdAt = Date()
                newProfile.displayName = ""
                newProfile.biometricEnabled = false
                return newProfile
            }
            displayName = profile.displayName ?? ""
            anonymousId = profile.anonymousId ?? ""
            createdAt = profile.createdAt ?? Date()
            biometricEnabled = profile.biometricEnabled
        } catch {
            alertMessage = "Failed to create profile: \(error.localizedDescription)"
            showAlert = true
        }
    }

    private func updateProfile(displayName: String? = nil, biometricEnabled: Bool? = nil) {
        Task {
            do {
                try await performOnContext { context in
                    let request = UserProfileEntity.fetchRequest()
                    request.fetchLimit = 1
                    guard let profile = try context.fetch(request).first else { return }

                    if let name = displayName {
                        profile.displayName = name
                    }
                    if let enabled = biometricEnabled {
                        profile.biometricEnabled = enabled
                    }
                }
            } catch {
                alertMessage = "Failed to update profile: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }

    var biometricType: LABiometryType {
        var error: NSError?
        guard biometricAuth.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        return biometricAuth.biometryType
    }

    var biometricIconName: String {
        switch biometricType {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        default: return "lock"
        }
    }
}
