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
    @State private var biometricEnabled = false
    @State private var showBiometricError = false
    @State private var biometricError: Error?
    @State private var displayName: String = ""
    
    private let context = LAContext()
    private var biometricType: LABiometryType {
        context.biometryType
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Account")) {
                    TextField("Display name", text: $displayName)
                        .onAppear {
                            displayName = userVM.displayName ?? ""
                        }
                        .onChange(of: displayName) { newValue in
                            userVM.updateDisplayName(newValue)
                        }
                }
                
                Section(header: Text("Security & Privacy")) {
                    Toggle("Biometric lock", isOn: $biometricEnabled)
                        .onChange(of: biometricEnabled) { newValue in
                            if newValue {
                                authenticateBiometrics()
                            } else {
                                userVM.updateBiometricEnabled(false)
                            }
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
            .onAppear {
                biometricEnabled = userVM.biometricEnabled ?? false
            }
            .alert(isPresented: $showBiometricError) {
                Alert(
                    title: Text("Biometric Authentication Failed"),
                    message: Text(biometricError?.localizedDescription ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK")) {
                        biometricEnabled = false
                    }
                )
            }
        }
    }
    
    private func authenticateBiometrics() {
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Enable biometric authentication for secure access to your journal"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, 
                                 localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    if success {
                        userVM.updateBiometricEnabled(true)
                    } else {
                        self.biometricError = error
                        self.showBiometricError = true
                        self.biometricEnabled = false
                    }
                }
            }
        } else {
            self.biometricError = error
            self.showBiometricError = true
            self.biometricEnabled = false
        }
    }
}
