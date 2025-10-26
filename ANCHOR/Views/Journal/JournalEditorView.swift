//
//  JournalEditorView.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//

import SwiftUI

struct JournalEditorView: View {
    var entry: JournalEntry? = nil
    var onSave: (JournalEntry) -> Void

    @Environment(\.presentationMode) private var presentation
    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var tagsText: String = ""
    @State private var error: Error?

    init(entry: JournalEntry? = nil, onSave: @escaping (JournalEntry) -> Void) {
        self.entry = entry
        self.onSave = onSave
        _title = State(initialValue: entry?.title ?? "")
        _bodyText = State(initialValue: entry?.body ?? "")
        _tagsText = State(initialValue: (entry?.tags ?? []).joined(separator: ", "))
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Title")) {
                    TextField("Optional title", text: $title)
                }
                Section(header: Text("Entry")) {
                    TextEditor(text: $bodyText).frame(minHeight: 200)
                }
                Section(header: Text("Tags (comma separated)")) {
                    TextField("e.g. anxiety, cravings", text: $tagsText)
                }
            }
            .navigationTitle(entry == nil ? "New Entry" : "Edit Entry")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { presentation.wrappedValue.dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let tags = Set(tagsText.split(separator: ",")
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty })
                        
                        do {
                            let entry = try JournalEntry(
                                id: entry?.id ?? UUID(),
                                createdAt: entry?.createdAt ?? Date(),
                                updatedAt: Date(),
                                title: title.isEmpty ? nil : title,
                                body: bodyText,
                                bodyFormat: "plain",
                                sentiment: entry?.sentiment,
                                tags: tags,
                                isLocked: entry?.isLocked ?? false,
                                version: (entry?.version ?? 0) + 1
                            )
                            onSave(entry)
                            presentation.wrappedValue.dismiss()
                        } catch {
                            self.error = error
                        }
                    }
                }
            }
            .alert(isPresented: .constant(error != nil)) {
                Alert(
                    title: Text("Error"),
                    message: Text(error?.localizedDescription ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK")) { error = nil }
                )
            }
        }
    }
}
