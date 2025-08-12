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
                        let tags = tagsText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                        var model = entry ?? JournalEntry(body: bodyText)
                        model.title = title
                        model.body = bodyText
                        model.tags = tags
                        onSave(model)
                        presentation.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
