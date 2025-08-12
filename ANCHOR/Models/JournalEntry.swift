//
//  JournalEntry.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import Foundation

public struct JournalEntry: Codable, Identifiable, Equatable {
    public var id: UUID
    public var date: Date
    public var title: String?
    public var body: String
    public var sentiment: Int?   // -1, 0, 1
    public var tags: [String]

    public init(id: UUID = .init(), date: Date = .init(), title: String? = nil, body: String, sentiment: Int? = nil, tags: [String] = []) {
        self.id = id
        self.date = date
        self.title = title
        self.body = body
        self.sentiment = sentiment
        self.tags = tags
    }
}
