//
//  SupportedCamerasArticle.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 14/11/2024.
//

import CoreBluetooth
import OrderedCollections
import SwiftUI

struct SupportedCamerasArticle: View {
    private let supportedPeripherals: OrderedDictionary<String, String> = [
        "ILCE-1": "Sony α1",
        "ILCE-1M2": "Sony α1 II",
        "ILCE-9M3": "Sony α9 III",
        "ILCE-7RM5": "Sony α7R V",
        "ILCE-7SM3": "Sony α7S III",
        "ILCE-7M4": "Sony α7 IV",
        "ILCE-7CR": "Sony α7CR",
        "ILCE-7CM2": "Sony α7C II",
        "ILCE-6700": "Sony α6700",
        "ZV-E1": "Sony ZV-E1",
        "ZV-E10M2": "Sony ZV-E10 II",
        "ZV-1M2": "Sony ZV-1 II",
        "ZV-1F": "Sony ZV-1F",
        "ILME-FX3": "Sony FX3",
        "ILME-FX30": "Sony FX30",
    ]

    @ViewBuilder var body: some View {
        Text("LocationAlpha works with Sony cameras that support Location Info Link.")

        Text("This includes:")

        ForEach(supportedPeripherals.elements, id: \.key) { peripheral in
            DottedListItem {
                Text("\(peripheral.value) (\(peripheral.key))")
            }
            .padding(.top, -8)
        }

        DottedListItem {
            Text("... and more!")
        }
        .padding(.top, -8)

        Text("Always make sure that your camera is running on latest firmware.")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        SupportedCamerasArticle()
    }
    .padding()
}
