//
//  UserProfileViewModel.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import Foundation
import LocalAuthentication
import SwiftUI

final class UserProfileViewModel: ObservableObject {
    @Published var profile: UserProfile
    @Published var biometricEnabled: Bool = false
    @Published var profileDisplayName: String = ""

    private let profileKey = "anchor.user.profile.v1"
    private let journalVM = JournalViewModel()

    init() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let p = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = p
        } else {
            self.profile = UserProfile()
        }
        self.profileDisplayName = profile.displayName ?? ""
        self.biometricEnabled = UserDefaults.standard.bool(forKey: "anchor.biometricEnabled")
    }

    func save() {
        profile.displayName = profileDisplayName
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: profileKey)
        }
        UserDefaults.standard.set(biometricEnabled, forKey: "anchor.biometricEnabled")
    }

    func toggleBiometric(_ enabled: Bool, completion: @escaping (Bool) -> Void) {
        let ctx = LAContext()
        var err: NSError?
        if ctx.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &err) {
            ctx.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Enable biometric unlock for Anchor") { success, _ in
                DispatchQueue.main.async {
                    self.biometricEnabled = success && enabled
                    self.save()
                    completion(self.biometricEnabled)
                }
            }
        } else {
            completion(false)
        }
    }

    func allJournalEntriesPacked() -> [JournalEntry] {
        return journalVM.exportableEntries()
    }
}
