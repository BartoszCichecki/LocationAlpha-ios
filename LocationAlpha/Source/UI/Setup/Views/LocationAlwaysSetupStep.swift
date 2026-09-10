//
//  LocationAlwaysSetupStep.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 14/11/2024.
//

import SwiftUI

struct LocationAlwaysSetupStep: View {
    @State var next: () -> Void

    @State var helper = LocationPermissionHelper()

    var body: some View {
        SetupStep(image: Image(systemName: "location.fill"),
                  title: "Almost there!",
                  subtitle: "Select \"Always allow\" to automatically detect when you are shooting photos.",
                  infoText: "Location data is stored on device and shared only with your camera.",
                  button: "Continue")
        {
            do {
                try await helper.requestPermission(always: true)
            } catch {
                // Ignored
            }
            next()
        }
    }
}

#Preview {
    LocationAlwaysSetupStep(next: {}, helper: .init())
}
