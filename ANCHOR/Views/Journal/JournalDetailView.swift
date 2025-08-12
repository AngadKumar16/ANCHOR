import SwiftUI

struct JournalDetailView: View {
    let entry: JournalEntryModel
    @ObservedObject var viewModel: JournalViewModel
    @State private var showingEdit = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(entry.title ?? "Untitled").font(.title2).bold()
                Text(entry.date.friendlyString()).font(.caption)
                Divider()
                Text(entry.body).padding(.vertical)
                if !entry.tags.isEmpty {
                    HStack { ForEach(entry.tags, id: \.self) { tag in
                        Text(tag).font(.caption).padding(6).background(Color(UIColor.systemGray5)).cornerRadius(6)
                    } }
                }
            }.padding()
        }
        .navigationBarItems(trailing: Button("Edit") { showingEdit = true })
        .sheet(isPresented: $showingEdit) {
            JournalEditorView(entry: JournalEntry(id: entry.id, date: entry.date, title: entry.title, body: entry.body, sentiment: entry.sentiment, tags: entry.tags)) { edited in
                Task {
                    try? await viewModel.update(entryId: edited.id, newTitle: edited.title, newBody: edited.body, newTags: edited.tags)
                    showingEdit = false
                }
            }
        }
    }
}
