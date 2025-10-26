import SwiftUI

struct EntryDetailView: View {
    @ObservedObject var viewModel: EntryDetailViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false
    @State private var showEditor = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with title and date
                VStack(alignment: .leading, spacing: 8) {
                    if let title = viewModel.entry.title, !title.isEmpty {
                        Text(title)
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    
                    HStack(spacing: 16) {
                        Label(viewModel.entry.createdAt.formatted(date: .abbreviated, time: .shortened), 
                              systemImage: "calendar")
                        
                        if let sentiment = viewModel.entry.sentiment {
                            SentimentIndicator(value: sentiment)
                        }
                        
                        if viewModel.entry.isLocked {
                            Label("Locked", systemImage: "lock.fill")
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.bottom, 8)
                
                // Tags
                if !viewModel.entry.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Array(viewModel.entry.tags.sorted()), id: \.self) { tag in
                                TagView(text: tag, style: .standard, size: .medium)
                            }
                        }
                    }
                }
                
                // Body
                Text(viewModel.entry.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                
                // Metadata
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.entry.createdAt != viewModel.entry.updatedAt {
                        DetailRow(title: "Updated", value: viewModel.entry.updatedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    
                    DetailRow(title: "Version", value: "\(viewModel.entry.version)")
                    
                    if let sentiment = viewModel.entry.sentiment {
                        DetailRow(title: "Sentiment", value: String(format: "%.1f%%", sentiment * 100))
                    }
                }
                .padding(.top)
                
                Spacer()
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showEditor = true }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: { showDeleteConfirmation = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Divider()
                    
                    Button(action: { viewModel.toggleLock() }) {
                        Label(
                            viewModel.entry.isLocked ? "Unlock Entry" : "Lock Entry",
                            systemImage: viewModel.entry.isLocked ? "lock.open" : "lock"
                        )
                    }
                    
                    Button(action: { viewModel.export() }) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Entry", isPresented: $showDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.delete()
                    dismiss()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this entry? This action cannot be undone.")
        }
        .sheet(isPresented: $showEditor) {
            NavigationView {
                JournalEntryEditorView(entry: viewModel.entry, viewModel: viewModel.journalViewModel)
            }
        }
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss { dismiss() }
        }
    }
}

// MARK: - Supporting Views

private struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        EntryDetailView(
            viewModel: EntryDetailViewModel(
                entry: .preview,
                journalViewModel: JournalViewModel(context: PersistenceController.preview.container.viewContext)
            )
        )
    }
}
