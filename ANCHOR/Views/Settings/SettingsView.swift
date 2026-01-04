//
//  SettingsView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//

import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @EnvironmentObject private var userVM: UserProfileViewModel
    @State private var showBiometricError = false
    @State private var biometricError: Error?

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    TextField("Display name", text: $userVM.displayName)
                }
                
                Section(header: Text("Security & Privacy")) {
                    Toggle(isOn: $userVM.biometricEnabled) {
                        Text("Biometric lock")
                    }
                    NavigationLink("Privacy Settings", destination: PrivacySettingsView())
                }
                
                Section(header: Text("Export")) {
                    Button("Export Data") {
                        let presenter = UIApplication.shared.connectedScenes
                            .compactMap { $0 as? UIWindowScene }
                            .flatMap { $0.windows }
                            .first { $0.isKeyWindow }?.rootViewController
                        DataExportService.shared.exportAllJournalEntries(presenting: presenter)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert(isPresented: $showBiometricError) {
                Alert(
                    title: Text("Biometric Authentication Failed"),
                    message: Text(biometricError?.localizedDescription ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}
