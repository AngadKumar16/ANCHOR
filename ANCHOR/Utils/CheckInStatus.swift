//
//  CheckInStatus.swift
//  ANCHOR
//
//  Created by Angad Kumar on 10/26/25.
//

import Foundation

/// Represents the status of a user's check-in
public enum CheckInStatus: String, Codable, CaseIterable {
    case notStarted
    case inProgress
    case completed
}
