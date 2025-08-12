//
//  UserProfile.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import Foundation

public struct UserProfile: Codable, Identifiable {
    public var id: UUID
    public var displayName: String?
    public var anonymousId: String? // could be used for anonymized peer support
    public var createdAt: Date

    public init(id: UUID = .init(), displayName: String? = nil, anonymousId: String? = nil, createdAt: Date = .init()) {
        self.id = id
        self.displayName = displayName
        self.anonymousId = anonymousId
        self.createdAt = createdAt
    }
}
