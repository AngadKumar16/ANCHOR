// Auto-generated FeatureRegistry to ensure views are linked
import SwiftUI

@MainActor
func __registerFeaturesForLinking() {
    // Create mock data for views that require it
    let mockRiskResult = RiskAssessment(
        id: UUID(),
        date: Date()
    )
    
    // Get the shared view context
    let context = PersistenceController.shared.container.viewContext
    
    // Initialize view models
    let journalVM = JournalViewModel(context: context)
    let riskVM = RiskAssessmentViewModel(viewContext: context)
    let userProfileVM = UserProfileViewModel(viewContext: context)
    
    // Register views with required parameters
    _ = AIAnalysisServiceView()
    _ = DashboardView()
        .environmentObject(journalVM)
        .environmentObject(riskVM)
    
    // Journal related views
    _ = JournalEntryView()
        .environmentObject(journalVM)
    _ = JournalEntryEditorView(entry: nil, viewModel: journalVM)
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
        .environmentObject(userProfileVM)
    _ = PrivacySettingsView()
    
    // Onboarding views
    _ = OnboardingView()
        .environmentObject(AppState())
    _ = WelcomeView()
    _ = PermissionsView()
    _ = PrivacyDisclaimerView(onAccept: {}, onDecline: {})
    _ = FinishSetupView()
    _ = SplashScreenView(onComplete: {})
    
    // Other feature views
    _ = BreathingExerciseView()
    _ = CheckInView()
}
