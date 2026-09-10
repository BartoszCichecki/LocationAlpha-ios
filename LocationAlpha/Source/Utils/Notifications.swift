//
//  Notifications.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 24/10/2024.
//

import UserNotifications

enum Notifications {
    static func notifyDevice(connected device: Device) {
        notify(group: .device(device.identifier),
               title: "Connected",
               message: "\(device.displayName ?? "Camera") is now connected.")
    }

    static func notifyDevice(disconnected device: Device) {
        notify(group: .device(device.identifier),
               title: "Disconnected",
               message: "\(device.displayName ?? "Camera") was disconnected.")
    }

    static func notifyPaused() {
        removeAll()
        notify(group: .location,
               title: "Paused",
               message: "Location tracking will resume automatically when a camera connects.")
    }

    static func notifyResumed() {
        remove(group: .location)
    }
}

private extension Notifications {
    enum Group {
        case device(UUID)
        case location

        var identifier: String {
            switch self {
            case let .device(uuid): "device-\(uuid.uuidString)"
            case .location: "location"
            }
        }

        var interruptionLevel: UNNotificationInterruptionLevel {
            switch self {
            case .device: .active
            case .location: .passive
            }
        }
    }

    static func notify(group: Group, title: String, message body: String? = nil) {
        let notification = UNMutableNotificationContent()
        notification.title = title
        if let body {
            notification.body = body
        }
        notification.interruptionLevel = group.interruptionLevel
        let request = UNNotificationRequest(identifier: group.identifier,
                                            content: notification,
                                            trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    static func removeAll() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    static func remove(group: Group) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [group.identifier])
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [group.identifier])
    }
}
