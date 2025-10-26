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
    var responses: [String: String] = [:]
    
    enum CodingKeys: String, CodingKey {
        case id, date, score, riskLevel, responses
    }
    
    init(id: UUID = UUID(), date: Date = Date()) {
        self.id = id
        self.date = date
    }
    
    // Custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(date, forKey: .date)
        try container.encode(score, forKey: .score)
        try container.encode(riskLevel, forKey: .riskLevel)
        try container.encode(responses, forKey: .responses)
    }
    
    // Custom decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        date = try container.decode(Date.self, forKey: .date)
        score = try container.decode(Int.self, forKey: .score)
        riskLevel = try container.decode(String.self, forKey: .riskLevel)
        responses = try container.decodeIfPresent([String: String].self, forKey: .responses) ?? [:]
    }
}
