//
//  PairingCameraArticle.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 14/11/2024.
//

import SwiftUI

struct PairingCameraArticle: View {
    var body: some View {
        Text("If your camera is not connecting automatically, it might require pairing with your phone first.")

        Text("Your camera")
            .font(.headline)
            .padding(.top, 16)

        NumberedListItem(number: 1) {
            Text("Turn on Bluetooth")
        }
        NumberedListItem(number: 2) {
            Text("Go to **Manage Paired Device** — if your phone is listed there, remove it")
        }
        NumberedListItem(number: 3) {
            Text("Turn on **Location Link Info**")
        }
        NumberedListItem(number: 4) {
            Text("Turn on **Auto Time Correct** and **Auto Area Adjust**")
        }
        NumberedListItem(number: 5) {
            Text("Select **Pairing** option")
        }

        Text("On most cameras, these settings are in the Network menu. You can skip options that are not available on your camera.")
            .font(.callout)

        Text("Your phone")
            .font(.headline)
            .padding(.top, 16)

        NumberedListItem(number: 1) {
            Text("Turn on Bluetooth")
        }
        NumberedListItem(number: 2) {
            Text("Check paired devices in Settings app, then Bluetooth — if your camera is listed there, remove it")
        }
        NumberedListItem(number: 3) {
            Text("Go back to LocationAlpha")
        }
        NumberedListItem(number: 4) {
            Text("Tap **Pair** next to your camera")
        }
        NumberedListItem(number: 5) {
            Text("Follow instructions on your phone and camera to complete pairing")
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        PairingCameraArticle()
    }
    .padding()
}
