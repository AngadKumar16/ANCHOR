import Foundation

final class APIClient {
    static let shared = APIClient()
    private init() {}

    private var baseURL: URL {
        return URL(string: "http://127.0.0.1:8000")!
    }

    func get<T: Decodable>(_ path: String) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(T.self, from: data)
    }

    func post<T: Decodable, U: Encodable>(_ path: String, _ payload: U) async throws -> T {
        let url = baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(payload)
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

/// AUTO-GENERATED API METHODS:



// AUTO-GENERATED: MoodTrackingInterfaceViewModel API methods
extension APIClient {
    func fetchMoodTrackingInterfaceViewModels() async throws -> [MoodTrackingInterfaceViewModelModel] {
        return try await get("/moodtrackinginterfaceviewmodels")
    }
    func postMoodTrackingInterfaceViewModel(_ payload: MoodTrackingInterfaceViewModelModel) async throws -> MoodTrackingInterfaceViewModelModel {
        return try await post("/moodtrackinginterfaceviewmodel", payload)
    }
}


// AUTO-GENERATED: AIAnalysisService API methods
extension APIClient {
    func fetchAIAnalysisServices() async throws -> [AIAnalysisServiceModel] {
        return try await get("/aianalysisservices")
    }
    func postAIAnalysisService(_ payload: AIAnalysisServiceModel) async throws -> AIAnalysisServiceModel {
        return try await post("/aianalysisservice", payload)
    }
}


// AUTO-GENERATED: DashboardView API methods
extension APIClient {
    func fetchDashboardViews() async throws -> [DashboardViewModel] {
        return try await get("/dashboardviews")
    }
    func postDashboardView(_ payload: DashboardViewModel) async throws -> DashboardViewModel {
        return try await post("/dashboardview", payload)
    }
}


// AUTO-GENERATED: JournalEntryView API methods
extension APIClient {
    func fetchJournalEntryViews() async throws -> [JournalEntryViewModel] {
        return try await get("/journalentryviews")
    }
    func postJournalEntryView(_ payload: JournalEntryViewModel) async throws -> JournalEntryViewModel {
        return try await post("/journalentryview", payload)
    }
}


// AUTO-GENERATED: ConflictResolutionViewModel API methods
extension APIClient {
    func fetchConflictResolutionViewModels() async throws -> [ConflictResolutionViewModelModel] {
        return try await get("/conflictresolutionviewmodels")
    }
    func postConflictResolutionViewModel(_ payload: ConflictResolutionViewModelModel) async throws -> ConflictResolutionViewModelModel {
        return try await post("/conflictresolutionviewmodel", payload)
    }
}


// AUTO-GENERATED: EmailpasswordLoginViewModel API methods
extension APIClient {
    func fetchEmailpasswordLoginViewModels() async throws -> [EmailpasswordLoginViewModelModel] {
        return try await get("/emailpasswordloginviewmodels")
    }
    func postEmailpasswordLoginViewModel(_ payload: EmailpasswordLoginViewModelModel) async throws -> EmailpasswordLoginViewModelModel {
        return try await post("/emailpasswordloginviewmodel", payload)
    }
}


// AUTO-GENERATED: EntryCategorizationtaggingViewModel API methods
extension APIClient {
    func fetchEntryCategorizationtaggingViewModels() async throws -> [EntryCategorizationtaggingViewModelModel] {
        return try await get("/entrycategorizationtaggingviewmodels")
    }
    func postEntryCategorizationtaggingViewModel(_ payload: EntryCategorizationtaggingViewModelModel) async throws -> EntryCategorizationtaggingViewModelModel {
        return try await post("/entrycategorizationtaggingviewmodel", payload)
    }
}


// AUTO-GENERATED: ImplementBackuprestoreFunctionalityViewModel API methods
extension APIClient {
    func fetchImplementBackuprestoreFunctionalityViewModels() async throws -> [ImplementBackuprestoreFunctionalityViewModelModel] {
        return try await get("/implementbackuprestorefunctionalityviewmodels")
    }
    func postImplementBackuprestoreFunctionalityViewModel(_ payload: ImplementBackuprestoreFunctionalityViewModelModel) async throws -> ImplementBackuprestoreFunctionalityViewModelModel {
        return try await post("/implementbackuprestorefunctionalityviewmodel", payload)
    }
}


// AUTO-GENERATED: ImplementUserAuthenticationServiceViewModel API methods
extension APIClient {
    func fetchImplementUserAuthenticationServiceViewModels() async throws -> [ImplementUserAuthenticationServiceViewModelModel] {
        return try await get("/implementuserauthenticationserviceviewmodels")
    }
    func postImplementUserAuthenticationServiceViewModel(_ payload: ImplementUserAuthenticationServiceViewModelModel) async throws -> ImplementUserAuthenticationServiceViewModelModel {
        return try await post("/implementuserauthenticationserviceviewmodel", payload)
    }
}


// AUTO-GENERATED: InitialSyncImplementationViewModel API methods
extension APIClient {
    func fetchInitialSyncImplementationViewModels() async throws -> [InitialSyncImplementationViewModelModel] {
        return try await get("/initialsyncimplementationviewmodels")
    }
    func postInitialSyncImplementationViewModel(_ payload: InitialSyncImplementationViewModelModel) async throws -> InitialSyncImplementationViewModelModel {
        return try await post("/initialsyncimplementationviewmodel", payload)
    }
}
