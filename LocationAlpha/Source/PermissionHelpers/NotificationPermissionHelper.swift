//
//  NotificationPermissionHelper.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 14/11/2024.
//

import UserNotifications

@MainActor struct NotificationPermissionHelper {
    enum Status {
        case accepted
        case denied
    }

    @discardableResult func requestPermission() async throws -> Status {
        let result = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert])
        return result ? .accepted : .denied
    }
}
