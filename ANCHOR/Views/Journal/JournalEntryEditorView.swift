import SwiftUI
import Combine

struct JournalEntryEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: JournalEntryEditorViewModel
    @FocusState private var focusedField: Field?
    @State private var showTagEditor = false
    
    enum Field: Hashable {
        case title, body
    }
    
    init(entry: JournalEntry? = nil, viewModel: JournalViewModel) {
        _viewModel = StateObject(wrappedValue: JournalEntryEditorViewModel(entry: entry, journalViewModel: viewModel))
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Title (optional)", text: $viewModel.title)
                        .font(.headline)
                        .focused($focusedField, equals: .title)
                        .submitLabel(.next)
                        .onSubmit { focusedField = .body }
                    
                    TextEditor(text: $viewModel.body)
                        .focused($focusedField, equals: .body)
                        .frame(minHeight: 200)
                        .overlay(
                            viewModel.body.isEmpty ?
                            Text("Write your thoughts here...")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                            : nil,
                            alignment: .topLeading
                        )
                }
                
                Section("Tags") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(Array(viewModel.tags), id: \.self) { tag in
                                TagView(name: tag, isSelected: true) {
                                    viewModel.tags.remove(tag)
                                }
                            }
                            
                            Button(action: { showTagEditor = true }) {
                                Label("Add Tag", systemImage: "plus.circle")
                                    .font(.caption)
                            }
                            .buttonStyle(.bordered)
                            .tint(.accentColor)
                        }
                        .padding(.vertical, 4)
                    }
                }
                
                Section {
                    Toggle("Lock Entry", isOn: $viewModel.isLocked)
                    
                    if let sentiment = viewModel.sentiment {
                        HStack {
                            Text("Sentiment")
                            Spacer()
                            SentimentIndicator(value: sentiment)
                        }
                    }
                }
                
                if viewModel.isEditing {
                    Section("Entry Details") {
                        HStack {
                            Text("Created")
                            Spacer()
                            Text(viewModel.createdAt.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Last Updated")
                            Spacer()
                            Text(viewModel.updatedAt.formatted(date: .abbreviated, time: .shortened))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Entry" : "New Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isEditing ? "Done" : "Save") {
                        Task {
                            await viewModel.save()
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.isValid)
                }
                
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button(action: { focusedField = nil }) {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                }
            }
            .onAppear {
                if viewModel.title.isEmpty {
                    focusedField = .title
                } else {
                    focusedField = .body
                }
            }
            .sheet(isPresented: $showTagEditor) {
                TagEditor(selectedTags: $viewModel.tags)
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "An unknown error occurred")
            }
        }
    }
}

// MARK: - Supporting Views

private struct TagView: View {
    let name: String
    let isSelected: Bool
    let onDelete: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 4) {
            Text(name)
                .font(.caption)
                .lineLimit(1)
            
            if let onDelete = onDelete {
                Button(action: onDelete) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.2))
        .cornerRadius(15)
    }
}

private struct SentimentIndicator: View {
    let value: Double // -1.0 to 1.0
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "face.smiling")
                .foregroundColor(sentimentColor)
            
            ProgressView(value: (value + 1) / 2)
                .progressViewStyle(.linear)
                .frame(width: 100)
            
            Text("\(Int(abs(value) * 100))%")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .trailing)
        }
    }
    
    private var sentimentColor: Color {
        if value > 0.3 {
            return .green
        } else if value < -0.3 {
            return .red
        } else {
            return .gray
        }
    }
}

// MARK: - Preview

#Preview {
    let viewModel = JournalViewModel(context: PersistenceController.preview.container.viewContext)
    return JournalEntryEditorView(entry: .preview, viewModel: viewModel)
}

#Preview("New Entry") {
    let viewModel = JournalViewModel(context: PersistenceController.preview.container.viewContext)
    return JournalEntryEditorView(viewModel: viewModel)
}
