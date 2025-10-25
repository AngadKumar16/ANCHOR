import Foundation
import Combine

@MainActor
final class JournalEntryEditorViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var title: String
    @Published var body: String
    @Published var tags: Set<String>
    @Published var isLocked: Bool
    @Published var sentiment: Double?
    @Published var showError = false
    @Published private(set) var errorMessage: String?
    
    // MARK: - Private Properties
    private let journalViewModel: JournalViewModel
    private let originalEntry: JournalEntry?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Computed Properties
    var isEditing: Bool { originalEntry != nil }
    var createdAt: Date { originalEntry?.createdAt ?? Date() }
    var updatedAt: Date { originalEntry?.updatedAt ?? Date() }
    var isValid: Bool { !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    
    // MARK: - Initialization
    init(entry: JournalEntry? = nil, journalViewModel: JournalViewModel) {
        self.originalEntry = entry
        self.journalViewModel = journalViewModel
        
        // Initialize with entry data or default values
        self.title = entry?.title ?? ""
        self.body = entry?.body ?? ""
        self.tags = entry?.tags ?? []
        self.isLocked = entry?.isLocked ?? false
        self.sentiment = entry?.sentiment
        
        // Setup sentiment analysis when body changes
        setupSentimentAnalysis()
    }
    
    // MARK: - Public Methods
    func save() async {
        do {
            let entry = try JournalEntry(
                id: originalEntry?.id ?? UUID(),
                createdAt: createdAt,
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                body: body.trimmingCharacters(in: .whitespacesAndNewlines),
                tags: tags,
                isLocked: isLocked
            )
            
            try entry.validate()
            
            if isEditing {
                try await journalViewModel.updateEntry(entry, title: title, body: body, tags: tags)
            } else {
                try await journalViewModel.createEntry(title: title, body: body, tags: tags)
            }
            
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Private Methods
    private func setupSentimentAnalysis() {
        $body
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] text in
                guard let self = self, !text.isEmpty else { return }
                Task {
                    self.sentiment = await self.analyzeSentiment(text: text)
                }
            }
            .store(in: &cancellables)
    }
    
    private func analyzeSentiment(text: String) async -> Double? {
        // In a real app, this would call your AIAnalysisService
        // For now, we'll return a mock value
        return nil
    }
    
    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
        Logger.log("JournalEntryEditor error: \(error)")
    }
}

// MARK: - Preview Support
#if DEBUG
extension JournalEntryEditorViewModel {
    static var preview: JournalEntryEditorViewModel {
        let viewModel = JournalViewModel(context: PersistenceController.preview.container.viewContext)
        return JournalEntryEditorViewModel(entry: .preview, journalViewModel: viewModel)
    }
}
#endif
