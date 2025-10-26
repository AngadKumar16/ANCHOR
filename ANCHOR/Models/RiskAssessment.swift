//
//  RiskAssessment.swift
//  ANCHOR
//
//  Created by Angad Kumar on 10/25/25.
//

import Foundation

struct RiskAssessment: Identifiable, Codable {
    let id: UUID
    let date: Date
    var score: Int = 0
    var riskLevel: String = "low"
    var responses: [String: Any] = [:]
    
    init(id: UUID = UUID(), date: Date = Date()) {
        self.id = id
        self.date = date
    }
}
