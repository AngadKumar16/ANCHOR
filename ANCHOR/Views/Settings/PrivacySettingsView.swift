//
//  PrivacySettingsView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import SwiftUI

struct PrivacySettingsView: View {
    @AppStorage("optInIcloud") var optInIcloud = false

    var body: some View {
        Form {
            Toggle("Opt into iCloud backup (optional)", isOn: $optInIcloud)
            Text("All data is encrypted locally. If you opt into iCloud, your encrypted blobs may be stored in iCloud private DB.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .navigationTitle("Privacy")
    }
}
