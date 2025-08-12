//
//  Logger.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//

import Foundation

enum Logger {
    static func log(_ message: String) {
        #if DEBUG
        print("[Anchor] \(message)")
        #else
        // In production: forward to an on-device logging endpoint or nothing.
        #endif
    }
}
