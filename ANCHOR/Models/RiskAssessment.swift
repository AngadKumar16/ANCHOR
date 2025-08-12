//
//  RiskAssessment.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import Foundation

public struct RiskAssessment: Codable, Identifiable {
    public var id: UUID
    public var date: Date
    public var score: Double    // 0.0 - 100.0
    public var reason: String?

    public init(id: UUID = .init(), date: Date = .init(), score: Double = 0, reason: String? = nil) {
        self.id = id
        self.date = date
        self.score = score
        self.reason = reason
    }
}
