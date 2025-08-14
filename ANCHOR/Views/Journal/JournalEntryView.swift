//
//  JournalEntryView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import SwiftUI

struct JournalEntryView: View {
    @EnvironmentObject var journalVM: JournalViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var title: String = ""
    @State private var entryText: String = ""
    @State private var selectedTags: Set<String> = []
    @State private var isAnalyzing = false
    
    let entry: JournalEntryModel?
    
    private let availableTags = [
        "Grateful", "Anxious", "Happy", "Sad", "Motivated", "Tired",
        "Hopeful", "Stressed", "Calm", "Excited", "Worried", "Peaceful"
    ]
    
    init(entry: JournalEntryModel? = nil) {
        self.entry = entry
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Title Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title (Optional)")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("How are you feeling today?", text: $title)
                            .textFieldStyle(.roundedBorder)
                            .font(.title3)
                    }
                    
                    // Body Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Thoughts")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemGray6))
                                .frame(minHeight: 200)
                            
                            if entryText.isEmpty {
                                Text("Write about your day, feelings, thoughts, or anything on your mind...")
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            }
                            
                            TextEditor(text: $entryText)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.clear)
                        }
                    }
                    
                    // Tags Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tags")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                            ForEach(availableTags, id: \.self) { tag in
                                TagButton(
                                    tag: tag,
                                    isSelected: selectedTags.contains(tag),
                                    action: { toggleTag(tag) }
                                )
                            }
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle(entry == nil ? "New Entry" : "Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: saveEntry) {
                        if isAnalyzing {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                    .scaleEffect(0.8)
                                Text("Saving...")
                            }
                        } else {
                            Text("Save")
                                .fontWeight(.semibold)
                        }
                    }
                    .disabled(entryText.isEmpty || isAnalyzing)
                }
            }
        }
        .onAppear {
            if let entry = entry {
                title = entry.title ?? ""
                entryText = entry.body
                selectedTags = Set(entry.tags)
            }
        }
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
    
    private func saveEntry() {
        guard !entryText.isEmpty else { return }
        
        isAnalyzing = true
        
        Task {
            do {
                if let existingEntry = entry {
                    // Update existing entry
                    try await journalVM.update(
                        entryId: existingEntry.id,
                        newTitle: title.isEmpty ? nil : title,
                        newBody: entryText,
                        newTags: Array(selectedTags)
                    )
                } else {
                    // Create new entry
                    try await journalVM.add(
                        title: title.isEmpty ? nil : title,
                        body: entryText,
                        tags: Array(selectedTags)
                    )
                }
                
                await MainActor.run {
                    isAnalyzing = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    // Could show an error alert here in the future
                    Logger.log("Failed to save journal entry: \(error)")
                }
            }
        }
    }
}

private struct TagButton: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

#Preview {
    JournalEntryView()
        .environmentObject(JournalViewModel())
}
