//
//  ModelExtensions.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//

import Foundation

// MARK: - JournalEntry Extensions

extension JournalEntry {
    public var displayTitle: String {
        if let t = title, !t.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return t
        }
        // fallback to short snippet
        let snippet = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if snippet.isEmpty { return "Untitled" }
        return snippet.count <= 25 ? snippet : String(snippet.prefix(25)) + "…"
    }

    public var isoDateString: String {
        ISO8601DateFormatter().string(from: createdAt)
    }
}

// MARK: - RiskAssessment Extensions

extension RiskAssessment {
    public var isoDateString: String {
        ISO8601DateFormatter().string(from: date)
    }
}

// MARK: - UserProfile Extensions

extension UserProfile {
    public var isoCreatedAtString: String {
        ISO8601DateFormatter().string(from: createdAt)
    }
    
    public var displayNameOrAnonymous: String {
        displayName?.isEmpty == false ? displayName! : "Anonymous"
    }
    
    public var anonymizedId: String {
        anonymousId?.isEmpty == false ? anonymousId! : "Anonymous-\(id.uuidString.prefix(8))"
    }
    
    public var displayNameOrAnonymizedId: String {
        if let name = displayName, !name.isEmpty {
            return name
        }
        return anonymizedId
    }
    
    public var displayNameOrId: String {
        if let name = displayName, !name.isEmpty {
            return name
        }
        return "User-\(id.uuidString.prefix(8))"
    }
}

// MARK: - JournalEntryModel

public struct JournalEntryModel: Identifiable, Codable {
    public var id: UUID
    public var date: Date
    public var title: String?
    public var body: String
    public var sentiment: Double
    public var tags: [String]
}

// MARK: - JournalEntryEntity Extensions

public extension JournalEntryEntity {
    func toModel() -> JournalEntryModel {
        return JournalEntryModel(
            id: self.id,
            date: self.createdAt,
            title: self.title,
            body: self.body,
            sentiment: self.sentiment,
            tags: self.tagsArray
        )
    }
}
