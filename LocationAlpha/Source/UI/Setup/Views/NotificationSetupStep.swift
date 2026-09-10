//
//  NotificationSetupStep.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 14/11/2024.
//

import SwiftUI

struct NotificationSetupStep: View {
    @State var next: () -> Void

    @State var helper = NotificationPermissionHelper()

    var body: some View {
        SetupStep(image: Image(systemName: "bell"),
                  title: "Notifications",
                  subtitle: "Receive notifications when camera connects or disconnects.",
                  button: "Continue")
        {
            do {
                try await helper.requestPermission()
            } catch {
                // Ignored
            }
            next()
        }
    }
}

#Preview {
    NotificationSetupStep {}
}
