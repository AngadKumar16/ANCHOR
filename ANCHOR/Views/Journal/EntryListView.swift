import SwiftUI
import CoreData

struct EntryListView: View {
    @StateObject private var viewModel: JournalViewModel
    @State private var showNewEntry = false
    @State private var searchText = ""
    @State private var selectedFilter: EntryFilter = .all
    @State private var sortOrder: EntrySortOrder = .newestFirst
    @State private var showFilters = false
    
    enum EntryFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case locked = "Locked"
        case tagged = "Tagged"
        case recent = "Recent"
        
        var id: String { self.rawValue }
    }
    
    enum EntrySortOrder: String, CaseIterable, Identifiable {
        case newestFirst = "Newest First"
        case oldestFirst = "Oldest First"
        case titleAZ = "Title (A-Z)"
        case sentiment = "Sentiment"
        
        var id: String { self.rawValue }
    }
    
    init(context: NSManagedObjectContext = PersistenceController.shared.container.viewContext) {
        _viewModel = StateObject(wrappedValue: JournalViewModel(context: context))
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.entries.isEmpty {
                    emptyStateView
                } else {
                    entryListView
                }
            }
            .navigationTitle("Journal")
            .searchable(text: $searchText, prompt: "Search entries...")
            .onChange(of: searchText) { _ in
                viewModel.searchText = searchText
            }
            .onChange(of: selectedFilter) { _ in
                applyFilters()
            }
            .onChange(of: sortOrder) { _ in
                applySort()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showFilters.toggle() }) {
                        Label("Filters", systemImage: "line.3.horizontal.decrease.circle")
                            .symbolVariant(showFilters ? .fill : .none)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showNewEntry = true }) {
                        HStack {
                            Image(systemName: "plus.circle")
                            Text("New Entry")
                        }
                        .padding(8)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.top)
                }
            }
            .sheet(isPresented: $showNewEntry) {
                NavigationView {
                    JournalEntryEditorView(viewModel: viewModel)
                }
            }
            .refreshable {
                await viewModel.loadMore()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("No Entries Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start by adding your first journal entry")
                .foregroundColor(.secondary)
            
            Button(action: { showNewEntry = true }) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("New Entry")
                }
                .padding(8)
            }
            .buttonStyle(.borderedProminent)
            .padding(.top)
        }
        .multilineTextAlignment(.center)
        .padding()
    }
    
    private var entryListView: some View {
        List {
            if showFilters {
                Section("Filters & Sort") {
                    Picker("Filter", selection: $selectedFilter) {
                        ForEach(EntryFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    
                    Picker("Sort By", selection: $sortOrder) {
                        ForEach(EntrySortOrder.allCases, id: \.self) { order in
                            Text(order.rawValue).tag(order)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            ForEach(viewModel.entries) { entry in
                NavigationLink(destination: {
                    EntryDetailView(
                        viewModel: EntryDetailViewModel(
                            entry: entry,
                            journalViewModel: viewModel
                        )
                    )
                }) {
                    EntryRow(entry: entry)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task {
                            try? await viewModel.delete(entries: [entry])
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Button {
                        // Toggle lock status
                        Task {
                            try? await viewModel.updateEntry(
                                entry,
                                isLocked: !entry.isLocked
                            )
                        }
                    } label: {
                        Label(
                            entry.isLocked ? "Unlock" : "Lock",
                            systemImage: entry.isLocked ? "lock.open" : "lock"
                        )
                    }
                    .tint(entry.isLocked ? .green : .orange)
                }
            }
            
            if viewModel.canLoadMore() {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .onAppear {
                        if viewModel.canLoadMore() {
                            viewModel.loadMore()
                        }
                    }
            }
        }
        .listStyle(.insetGrouped)
    }
    
    private func applyFilters() {
        // In a real app, you would update the view model's filter state
        // and trigger a new fetch with the updated filters
        viewModel.loadMore()
    }
    
    private func applySort() {
        // In a real app, you would update the view model's sort order
        // and trigger a re-sort of the data
        viewModel.loadMore()
    }
}

// MARK: - Supporting Views

private struct EntryRow: View {
    let entry: JournalEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                if let title = entry.title, !title.isEmpty {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                } else {
                    Text("No Title")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .italic()
                }
                
                Spacer()
                
                if entry.isLocked {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                if let sentiment = entry.sentiment {
                    Circle()
                        .fill(sentimentColor(for: sentiment))
                        .frame(width: 12, height: 12)
                }
            }
            
            Text(entry.body)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            if !entry.tags.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(entry.tags.prefix(3)).sorted(), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.2))
                                .cornerRadius(10)
                        }
                        
                        if entry.tags.count > 3 {
                            Text("+\(entry.tags.count - 3) more")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            HStack {
                Text(entry.updatedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if entry.createdAt != entry.updatedAt {
                    Image(systemName: "pencil")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.top, 2)
        }
        .padding(.vertical, 8)
    }
    
    private func sentimentColor(for value: Double) -> Color {
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
    EntryListView(context: PersistenceController.preview.container.viewContext)
}
