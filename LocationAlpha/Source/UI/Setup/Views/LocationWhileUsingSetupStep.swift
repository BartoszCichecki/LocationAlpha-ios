//
//  LocationWhileUsingSetupStep.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 14/11/2024.
//

import SwiftUI

struct LocationWhileUsingSetupStep: View {
    @State var next: (Bool) -> Void

    @State var helper = LocationPermissionHelper()

    var body: some View {
        SetupStep(image: Image(systemName: "location"),
                  title: "Location",
                  subtitle: "Select \"Allow while using\" to allow access to your location and share it with your camera.",
                  infoText: "Location data is stored on device and shared only with your camera.",
                  button: "Continue")
        {
            do {
                let result = try await helper.requestPermission(always: false)
                next(result)
            } catch {
                next(false)
            }
        }
    }
}

#Preview {
    LocationWhileUsingSetupStep(next: { _ in }, helper: .init())
}
