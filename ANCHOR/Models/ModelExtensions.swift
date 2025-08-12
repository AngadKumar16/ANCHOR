//
//  Untitled.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//

import Foundation

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
        ISO8601DateFormatter().string(from: date)
    }
}
extension RiskAssessment {
    public var isoDateString: String {
        ISO8601DateFormatter().string(from: date)
    }
}
extension UserProfile {
    public var isoCreatedAtString: String {
        ISO8601DateFormatter().string(from: createdAt)
    }
}
extension UserProfile {
    public var displayNameOrAnonymous: String {
        displayName?.isEmpty == false ? displayName! : "Anonymous"
    }
}
extension UserProfile {
    public var anonymizedId: String {
        anonymousId?.isEmpty == false ? anonymousId! : "Anonymous-\(id.uuidString.prefix(8))"
    }
}
extension UserProfile {
    public var displayNameOrAnonymizedId: String {
        if let name = displayName, !name.isEmpty {
            return name
        }
        return anonymizedId
    }
}
extension UserProfile {
    public var displayNameOrId: String {
        if let name = displayName, !name.isEmpty {
            return name
        }
        return "User-\(id.uuidString.prefix(8))"
    }
}

