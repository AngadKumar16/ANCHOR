//
//  JournalEntry.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//

import Foundation

public struct JournalEntry: Codable, Identifiable, Equatable {
    public let id: UUID
    public let createdAt: Date
    public var updatedAt: Date
    public var title: String?
    public var body: String
    public var bodyFormat: String  // 'plain' or 'markdown'
    public var sentiment: Double?  // Range from -1.0 to 1.0
    public var tags: Set<String>
    public var isLocked: Bool
    public var version: Int
    
    public init(
        id: UUID = .init(),
        createdAt: Date = .init(),
        updatedAt: Date? = nil,
        title: String? = nil,
        body: String,
        bodyFormat: String = "plain",
        sentiment: Double? = nil,
        tags: Set<String> = [],
        isLocked: Bool = false,
        version: Int = 1
    ) throws {
        guard bodyFormat == "plain" || bodyFormat == "markdown" else {
            throw JournalError.invalidFormat
        }
        
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
        self.title = title
        self.body = body
        self.bodyFormat = bodyFormat
        self.sentiment = sentiment
        self.tags = tags
        self.isLocked = isLocked
        self.version = version
    }
    
    public func withUpdatedContent(title: String? = nil, body: String? = nil) throws -> JournalEntry {
        guard !isLocked else {
            throw JournalError.entryLocked
        }
        
        return try JournalEntry(
            id: self.id,
            createdAt: self.createdAt,
            updatedAt: Date(),
            title: title ?? self.title,
            body: body ?? self.body,
            bodyFormat: self.bodyFormat,
            sentiment: self.sentiment,
            tags: self.tags,
            isLocked: self.isLocked,
            version: self.version + 1
        )
    }
}

public enum JournalError: Error, LocalizedError {
    case invalidFormat
    case entryLocked
    case validationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid body format. Must be 'plain' or 'markdown'"
        case .entryLocked:
            return "This entry is locked and cannot be modified"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        }
    }
}

// MARK: - Validation
public extension JournalEntry {
    static let maxTitleLength = 100
    static let maxBodyLength = 10_000
    
    func validate() throws {
        if let title = title, title.count > Self.maxTitleLength {
            throw JournalError.validationFailed("Title exceeds maximum length of \(Self.maxTitleLength) characters")
        }
        
        if body.count > Self.maxBodyLength {
            throw JournalError.validationFailed("Body exceeds maximum length of \(Self.maxBodyLength) characters")
        }
        
        if body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw JournalError.validationFailed("Entry body cannot be empty")
        }
    }
}

// MARK: - Preview Helpers
#if DEBUG
extension JournalEntry {
    static let preview = try! JournalEntry(
        title: "My First Entry",
        body: "Today was a good day. I felt productive and accomplished my goals.",
        tags: ["reflection", "daily"],
        isLocked: false
    )
}
#endif
