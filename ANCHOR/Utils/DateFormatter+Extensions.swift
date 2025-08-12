//
//  DateFormatter+Extensions.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//

import Foundation

extension Date {
    func shortDateString() -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: self)
    }
}
extension DateFormatter {
    static let shared: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    func shortDateString(from date: Date) -> String {
        return self.string(from: date)
    }
}
