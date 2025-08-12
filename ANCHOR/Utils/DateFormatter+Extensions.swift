//
//  DateFormatter+Extensions.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//

import Foundation

extension Date {
    func friendlyString() -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: self)
    }
}

}
