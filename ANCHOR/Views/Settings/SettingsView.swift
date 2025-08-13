//
//  SettingsView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var userVM: UserProfileViewModel
    @State private var biometricEnabled = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    TextField("Display name", text: $userVM.displayName)
                }
                Section(header: Text("Security & Privacy")) {
                    Toggle("Biometric lock", isOn: $userVM.biometricEnabled)
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
            .onAppear {
                biometricEnabled = userVM.biometricEnabled
            }
        }
    }
}
