
import Foundation
import CoreML

final class AIAnalysisService {
    static let shared = AIAnalysisService()

    private var model: MLModel?

    private init() {
        // Attempt to load a local Core ML model named "risk_model_placeholder"
        if let url = Bundle.main.url(forResource: "risk_model_placeholder", withExtension: "mlmodelc") {
            do {
                model = try MLModel(contentsOf: url)
            } catch {
                model = nil
            }
        } else if Bundle.main.url(forResource: "risk_model_placeholder", withExtension: "mlmodel") != nil {
            // If .mlmodel not compiled, it's okay — we'll fallback below
            model = nil
        }
    }

    // Returns -1 negative, 0 neutral, 1 positive
    func analyzeSentiment(text: String) -> Int {
        // If we have a model and it accepts text input, you'd run it here.
        // For MVP fallback, use a simple word-list heuristic.
        let lower = text.lowercased()
        let positiveWords = ["good","grateful","happy","sober","well","calm","relieved"]
        let negativeWords = ["sad","alone","hopeless","urge","craving","relapse","anxious","angry","depressed"]

        var score = 0
        for w in positiveWords { if lower.contains(w) { score += 1 } }
        for w in negativeWords { if lower.contains(w) { score -= 1 } }
        if score > 0 { return 1 }
        if score < 0 { return -1 }
        return 0
    }
}
