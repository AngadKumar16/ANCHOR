//
//  RiskAssessmentViewModel.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import Foundation
import Combine

final class RiskAssessmentViewModel: ObservableObject {
    @Published var mood: Int = 1 // 0 low, 1 neutral, 2 high
    @Published var craving: Double = 0
    @Published var triggersText: String = ""
    @Published var latestResult: RiskAssessment?

    // Simple heuristic: base = craving*8 + (mood==2 ? 15 : mood==0 ? 5 : 0) + triggerFactor
    func calculate() {
        let triggerCount = triggersText.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }.count
        var score = craving * 8.0
        if mood == 2 { score += 15 }
        else if mood == 0 { score += 5 }
        score += Double(min(triggerCount, 5)) * 5.0
        score = min(max(score, 0.0), 100.0)
        let reason = "Craving: \(Int(craving)), Triggers: \(triggerCount), Mood: \(mood)"
        let res = RiskAssessment(score: score, reason: reason)
        self.latestResult = res
    }
}
