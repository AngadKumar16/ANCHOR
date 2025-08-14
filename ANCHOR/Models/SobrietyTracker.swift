//
//  SobrietyTracker.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/13/25.
//

import Foundation

class SobrietyTracker: ObservableObject {
    @Published var sobrietyStartDate: Date {
        didSet {
            UserDefaults.standard.set(sobrietyStartDate, forKey: "sobrietyStartDate")
        }
    }
    
    init() {
        if let savedDate = UserDefaults.standard.object(forKey: "sobrietyStartDate") as? Date {
            self.sobrietyStartDate = savedDate
        } else {
            // Default to today if no date is set
            self.sobrietyStartDate = Date()
            UserDefaults.standard.set(self.sobrietyStartDate, forKey: "sobrietyStartDate")
        }
    }
    
    var daysSober: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: sobrietyStartDate, to: Date())
        return max(0, components.day ?? 0)
    }
    
    var hoursSober: Int {
        let components = Calendar.current.dateComponents([.hour], from: sobrietyStartDate, to: Date())
        return max(0, components.hour ?? 0)
    }
    
    var formattedSobrietyTime: String {
        let days = daysSober
        let hours = hoursSober % 24
        
        if days > 0 {
            return days == 1 ? "1 day" : "\(days) days"
        } else {
            return hours == 1 ? "1 hour" : "\(hours) hours"
        }
    }
    
    var sobrietyStartDateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return "Sober since \(formatter.string(from: sobrietyStartDate))"
    }
    
    var nextMilestone: (days: Int, description: String) {
        let current = daysSober
        let milestones = [7, 14, 30, 60, 90, 180, 365, 730, 1095] // 1 week to 3 years
        
        for milestone in milestones {
            if current < milestone {
                return (milestone, milestoneName(for: milestone))
            }
        }
        
        // If past all milestones, calculate next year
        let nextYear = ((current / 365) + 1) * 365
        return (nextYear, "\(nextYear / 365) Year\(nextYear / 365 > 1 ? "s" : "")")
    }
    
    var progressToNextMilestone: Double {
        let next = nextMilestone.days
        let current = daysSober
        
        // Find previous milestone
        let milestones = [0, 7, 14, 30, 60, 90, 180, 365, 730, 1095]
        var previous = 0
        
        for milestone in milestones {
            if milestone <= current {
                previous = milestone
            } else {
                break
            }
        }
        
        let range = next - previous
        let progress = current - previous
        
        return range > 0 ? Double(progress) / Double(range) : 0.0
    }
    
    private func milestoneName(for days: Int) -> String {
        switch days {
        case 7: return "1 Week"
        case 14: return "2 Weeks"
        case 30: return "1 Month"
        case 60: return "2 Months"
        case 90: return "3 Months"
        case 180: return "6 Months"
        case 365: return "1 Year"
        case 730: return "2 Years"
        case 1095: return "3 Years"
        default: return "\(days) Days"
        }
    }
    
    func resetSobrietyDate(to date: Date) {
        sobrietyStartDate = date
    }
}
