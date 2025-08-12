//
//  JournalDetailView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import SwiftUI

struct JournalDetailView: View {
    @EnvironmentObject var viewModel: JournalViewModel
    let entry: JournalEntry
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(entry.displayTitle).font(.title2).bold()
                Text(entry.date, style: .date).font(.caption)
                Divider()
                Text(entry.body).padding(.vertical)
                if !entry.tags.isEmpty {
                    HStack {
                        ForEach(entry.tags, id: \.self) { t in
                            Text(t).font(.caption).padding(6).background(Color(UIColor.systemGray5)).cornerRadius(6)
                        }
                    }
                }
                Spacer()
            }.padding()
        }
        .navigationBarItems(trailing: Button("Edit") { showingEdit = true })
        .sheet(isPresented: $showingEdit) {
            JournalEditorView(entry: entry) { edited in
                viewModel.update(entry: edited)
                showingEdit = false
            }
        }
    }
}
