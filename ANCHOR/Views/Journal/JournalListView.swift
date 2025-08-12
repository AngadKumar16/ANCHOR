//
//  JournalListView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import SwiftUI

struct JournalListView: View {
    @EnvironmentObject var viewModel: JournalViewModel
    @State private var showingNew = false

    var body: some View {
        NavigationView {
            List {
                if viewModel.entries.isEmpty {
                    Text("No journal entries yet. Tap + to add one.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.entries.sorted(by: { $0.date > $1.date })) { entry in
                        NavigationLink(destination: JournalDetailView(entry: entry).environmentObject(viewModel)) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(entry.displayTitle).font(.headline)
                                HStack {
                                    Text(entry.date, style: .date).font(.caption)
                                    if let s = entry.sentiment {
                                        Image(systemName: s > 0 ? "smiley" : (s < 0 ? "frown" : "circle"))
                                            .font(.caption)
                                            .foregroundColor(s > 0 ? .green : (s < 0 ? .red : .gray))
                                    }
                                }
                            }
                        }
                    }
                    .onDelete(perform: viewModel.delete)
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNew = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNew) {
                JournalEditorView { new in
                    viewModel.add(entry: new)
                    showingNew = false
                }
            }
            .onAppear { viewModel.load() }
        }
    }
}
