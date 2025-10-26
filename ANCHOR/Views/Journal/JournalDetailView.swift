import SwiftUI

struct JournalDetailView: View {
    @ObservedObject var viewModel: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEdit = false
    
    let entry: JournalEntry
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(entry.title ?? "Untitled Entry")
                    .font(.title)
                    .padding(.bottom, 8)
                
                Text(entry.body)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if !entry.tags.isEmpty {
                    Text("Tags: \(entry.tags.joined(separator: ", "))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Entry Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEdit = true
                }
            }
        }
        .sheet(isPresented: $showingEdit) {
            NavigationView {
                JournalEditorView(entry: entry) { editedEntry in
                    Task {
                        try? await viewModel.updateEntry(
                            editedEntry,
                            title: editedEntry.title,
                            body: editedEntry.body,
                            tags: editedEntry.tags
                        )
                        dismiss()
                    }
                }
                .navigationTitle("Edit Entry")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
