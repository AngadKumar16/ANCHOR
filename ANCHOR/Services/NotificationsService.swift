//
//  NotificationsService.swift
//  ANCHOR
//
//  Created by Angad Kumar on 8/12/25.
//


import Foundation
import UserNotifications

final class NotificationsService {
    static let shared = NotificationsService()

    private init() {}

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, err in
            if let e = err { Logger.log("Notification auth error: \(e)") }
            completion(granted)
        }
    }

    func scheduleDailyReminder(hour: Int = 20, minute: Int = 0, id: String = "anchor.daily.checkin") {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
        var dc = DateComponents()
        dc.hour = hour
        dc.minute = minute
        let content = UNMutableNotificationContent()
        content.title = "Daily Check-in"
        content.body = "Tap to record a quick check-in with Anchor."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        let req = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(req) { error in
            if let e = error { Logger.log("Schedule notification error: \(e)") }
        }
    }

    func cancelReminder(id: String = "anchor.daily.checkin") {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
}
