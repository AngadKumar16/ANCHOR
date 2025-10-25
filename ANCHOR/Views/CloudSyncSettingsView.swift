import SwiftUI
import CloudKit

struct CloudSyncSettingsView: View {
    @StateObject private var viewModel = CloudSyncSettingsViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section(header: Text("iCloud Sync")) {
                Toggle("Enable iCloud Sync", isOn: $viewModel.isSyncEnabled)
                    .disabled(viewModel.isLoading)
                
                if viewModel.isSyncEnabled {
                    Toggle("Sync over Wi-Fi only", isOn: $viewModel.wiFiOnly)
                        .disabled(viewModel.isLoading)
                    
                    Toggle("Include attachments", isOn: $viewModel.includeAttachments)
                        .disabled(viewModel.isLoading)
                }
            }
            .onChange(of: viewModel.isSyncEnabled) { newValue in
                if newValue {
                    // Additional setup when enabling sync
                }
            }
            
            if viewModel.isSyncEnabled {
                Section {
                    Button(action: { Task { await viewModel.manualSync() } }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Sync Now")
                            
                            if viewModel.isLoading {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
                    
                    if let lastSyncDate = viewModel.lastSyncDate {
                        HStack {
                            Text("Last Sync")
                            Spacer()
                            Text(lastSyncDate.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    if viewModel.accountStatus != .available {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("iCloud Unavailable")
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
                    Section {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("Troubleshooting")) {
                    Button(role: .destructive) {
                        viewModel.showResetConfirmation = true
                    } label: {
                        Label("Reset Sync Data", systemImage: "arrow.triangle.2.circlepath")
                            .foregroundColor(.red)
                    }
                    .disabled(viewModel.isLoading)
                }
            } else {
                Section(footer: Text("Enable iCloud sync to keep your journal entries backed up and available across all your devices.")) {
                    EmptyView()
                }
            }
        }
        .navigationTitle("iCloud Sync")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationButton) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .alert("Reset Sync Data", isPresented: $viewModel.showResetConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                Task { await viewModel.resetSyncData() }
            }
        } message: {
            Text("This will remove all synced data from iCloud. Your local data will not be affected.")
        }
        .task {
            await viewModel.loadSettings()
        }
        .overlay {
            if viewModel.isLoading && viewModel.lastSyncDate == nil {
                ProgressView("Setting up iCloud...")
                    .padding()
                    .background(Color(.systemBackground).opacity(0.9))
                    .cornerRadius(10)
                    .shadow(radius: 10)
            }
        }
    }
}

// MARK: - Preview

struct CloudSyncSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            CloudSyncSettingsView()
        }
    }
}