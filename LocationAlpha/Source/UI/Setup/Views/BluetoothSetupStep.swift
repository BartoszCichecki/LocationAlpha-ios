//
//  BluetoothSetupStep.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 14/11/2024.
//

import SwiftUI

struct BluetoothSetupStep: View {
    @State var next: () -> Void

    @State var helper = BluetoothPermissionHelper()

    var body: some View {
        SetupStep(image: Image(systemName: "dot.radiowaves.left.and.right"),
                  title: "Bluetooth",
                  subtitle: "Bluetooth is used to connect to your camera.",
                  infoText: "LocationAlpha does not connect to or collect any information about Bluetooth devices around you.",
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
    BluetoothSetupStep(next: {}, helper: .init())
}
