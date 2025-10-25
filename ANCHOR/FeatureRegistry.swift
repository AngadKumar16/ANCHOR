// Auto-generated FeatureRegistry to ensure views are referenced
import SwiftUI

func __registerFeaturesForLinking() {
    // Create mock data for views that require it
    let mockRiskResult = RiskAssessment(
        id: UUID(),
        date: Date(),
        score: 5,
        riskLevel: .medium,
        responses: [:]
    )
    
    // Existing views in the project
    _ = AIAnalysisServiceView()
    _ = CloudSyncSettingsView()
    _ = DashboardView()
    _ = JournalEntryView()
    _ = JournalEntryEditorView()
    _ = JournalListView()
    _ = MoodTrackingView()
    _ = MoodHistoryView()
    _ = RiskAssessmentView()
    _ = RiskQuestionView()
    _ = RiskResultsView(result: mockRiskResult)
    _ = RiskAssessmentHistoryView()
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
