import SwiftUI

struct JournalListView: View {
    @StateObject private var vm = JournalViewModel()

    var body: some View {
        NavigationView {
            List {
                if vm.entries.isEmpty {
                    Text("No entries yet — tap + to add one").foregroundColor(.secondary)
                } else {
                    ForEach(vm.entries) { e in
                        NavigationLink(destination: JournalDetailView(entry: e, viewModel: vm)) {
                            VStack(alignment: .leading) {
                                Text(e.title ?? e.body.prefix(40).trimmingCharacters(in: .whitespacesAndNewlines) + (e.body.count > 40 ? "…" : ""))
                                Text(e.date, style: .date).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    .onDelete { idx in
                        Task { await vm.delete(at: idx) }
                    }
                }
            }
            .navigationTitle("Journal")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingNew) {
                JournalEditorView { new in
                    Task {
                        try? await vm.add(title: new.title, body: new.body, tags: new.tags)
                        showingNew = false
                    }
                }
            }
        }
    }

    @State private var showingNew = false
}
