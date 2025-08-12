//
//  DashboardView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import SwiftUI

struct DashboardView: View {
    @StateObject private var journalVM = JournalViewModel() // lightweight local copy
    @State private var showCheckIn = false

    var body: some View {
        NavigationView {
            VStack(spacing: 18) {
                HStack {
                    Text("Anchor").font(.largeTitle).bold()
                    Spacer()
                }.padding(.horizontal)

                VStack {
                    Text("Today's snapshot")
                        .font(.headline)
                    HStack {
                        VStack {
                            Text("Mood")
                            Text("🙂").font(.largeTitle)
                        }.frame(maxWidth: .infinity)
                        VStack {
                            Text("Craving")
                            Text("2/10").font(.headline)
                        }.frame(maxWidth: .infinity)
                    }.padding()
                }.background(RoundedRectangle(cornerRadius: 12).fill(Color(UIColor.secondarySystemGroupedBackground)))

                Button(action: { showCheckIn = true }) {
                    Label("Start Check-in", systemImage: "pencil")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Home")
            .sheet(isPresented: $showCheckIn) {
                CheckInView()
            }
        }
    }
}
