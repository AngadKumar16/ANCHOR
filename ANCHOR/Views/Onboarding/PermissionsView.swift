//
//  PermissionsView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import SwiftUI

struct PermissionsView: View {
    @State private var notificationsGranted = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Permissions").font(.title2)
            Text("Anchor needs permission to send reminders (optional). You can change this later in Settings.")
                .multilineTextAlignment(.center).foregroundColor(.secondary)
            Button("Enable Reminders") {
                NotificationsService.shared.requestAuthorization { granted in
                    DispatchQueue.main.async {
                        notificationsGranted = granted
                    }
                }
            }
            .buttonStyle(.bordered)
            Spacer()
        }.padding()
    }
}
