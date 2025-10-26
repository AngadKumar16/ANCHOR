// Auto-generated FeatureRegistry to ensure views are linked
import SwiftUI

func __registerFeaturesForLinking() {
    // Create mock data for views that require it
    let mockRiskResult = RiskAssessment(
        id: UUID(),
        date: Date(),
        score: 50, // Updated to use Int for score
        riskLevel: "medium", // Using string literal for risk level
        responses: [:] as [String: Any]
    )
    
    // Get the shared view context
    let context = PersistenceController.shared.container.viewContext
    
    // Initialize view models
    let journalVM = JournalViewModel(context: context)
    let riskVM = RiskAssessmentViewModel(viewContext: context)
    
    // Register views with required parameters
    _ = AIAnalysisServiceView()
    _ = CloudSyncSettingsView(viewModel: CloudSyncSettingsViewModel())
    _ = DashboardView()
        .environmentObject(journalVM)
        .environmentObject(riskVM)
    
    // Journal related views
    _ = JournalEntryView()
    _ = JournalEntryEditorView()
    _ = JournalListView()
        .environmentObject(journalVM)
    
    // Mood tracking views
    _ = MoodTrackingView()
    _ = MoodHistoryView()
    
    // Risk assessment views
    _ = RiskAssessmentView()
        .environmentObject(riskVM)
    _ = RiskQuestionView()
        .environmentObject(riskVM)
    _ = RiskResultsView(result: mockRiskResult)
    _ = RiskAssessmentHistoryView()
    
    // Settings views
    _ = SettingsView()
    _ = PrivacySettingsView()
    
    // Onboarding views
    _ = OnboardingView()
    _ = WelcomeView()
    _ = PermissionsView()
    _ = PrivacyDisclaimerView(onAccept: {}, onDecline: {})
    _ = FinishSetupView()
    _ = SplashScreenView()
    
    // Other feature views
    _ = BreathingExerciseView()
    _ = CheckInView()
}
