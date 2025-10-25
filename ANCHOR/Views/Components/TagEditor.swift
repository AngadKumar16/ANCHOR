import SwiftUI

struct TagEditor: View {
    @Binding var selectedTags: Set<String>
    @State private var newTagName = ""
    @State private var availableTags: [String] = ["personal", "work", "ideas", "reflection", "goals"]
    @Environment(\.dismiss) private var dismiss
    
    private var suggestedTags: [String] {
        let lowercasedSearch = newTagName.lowercased()
        return availableTags.filter { $0.lowercased().contains(lowercasedSearch) && !selectedTags.contains($0) }
    }
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Add New Tag")) {
                    HStack {
                        TextField("Tag name", text: $newTagName)
                            .textInputAutocapitalization(.never)
                            .disableAutocorrection(true)
                            .onSubmit { addNewTag() }
                        
                        Button(action: addNewTag) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.accentColor)
                        }
                        .disabled(newTagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                
                if !suggestedTags.isEmpty && !newTagName.isEmpty {
                    Section(header: Text("Suggestions")) {
                        ForEach(suggestedTags, id: \.self) { tag in
                            Button(action: { toggleTag(tag) }) {
                                HStack {
                                    Text(tag)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if selectedTags.contains(tag) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                    }
                }
                
                if !selectedTags.isEmpty {
                    Section(header: Text("Selected Tags")) {
                        ForEach(Array(selectedTags.sorted()), id: \.self) { tag in
                            Button(action: { toggleTag(tag) }) {
                                HStack {
                                    Text(tag)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                Section(header: Text("Available Tags")) {
                    ForEach(availableTags.filter { !selectedTags.contains($0) && !suggestedTags.contains($0) }, id: \.self) { tag in
                        Button(action: { toggleTag(tag) }) {
                            Text(tag)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Edit Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func addNewTag() {
        let tagName = newTagName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !tagName.isEmpty else { return }
        
        if !availableTags.contains(tagName) {
            availableTags.append(tagName)
        }
        
        selectedTags.insert(tagName)
        newTagName = ""
    }
    
    private func toggleTag(_ tag: String) {
        if selectedTags.contains(tag) {
            selectedTags.remove(tag)
        } else {
            selectedTags.insert(tag)
        }
    }
}

// MARK: - Preview

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTags: Set<String> = ["work", "ideas"]
        
        var body: some View {
            TagEditor(selectedTags: $selectedTags)
        }
    }
    
    return PreviewWrapper()
}
