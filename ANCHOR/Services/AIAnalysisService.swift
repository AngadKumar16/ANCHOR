import Foundation
import CoreML

final class AIAnalysisService {
    static let shared = AIAnalysisService()
    private var model: MLModel?

    private init() {
        // try to load compiled model; optional for MVP
        if let url = Bundle.main.url(forResource: "risk_model_placeholder", withExtension: "mlmodelc") {
            model = try? MLModel(contentsOf: url)
        }
    }

    // simple fallback sentiment: -1,0,1
    func analyzeSentiment(text: String) -> Int16 {
        let lower = text.lowercased()
        let pos = ["good","grateful","happy","sober","calm","relieved"]
        let neg = ["sad","alone","hopeless","urge","craving","relapse","anxious","depressed"]
        var s = 0
        for w in pos where lower.contains(w) { s += 1 }
        for w in neg where lower.contains(w) { s -= 1 }
        if s > 0 { return 1 }
        if s < 0 { return -1 }
        return 0
    }
}
