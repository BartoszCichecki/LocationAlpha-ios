//
//  ConnectingCameraArticle.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 14/11/2024.
//

import SwiftUI

struct ConnectingCameraArticle: View {
    var body: some View {
        Text("LocationAlpha will automatically connect to the camera, typically within a few seconds after the camera is turned on. If that does not happen, it might be necessary to pair your camera again.")

        Text("By default LocationAlpha try to connect to your camera at any time. If you enabled the **Connect when Power OFF** option on your camera, disable Quick Connect for it. You can manage cameras in settings.")

        Text("For more details, check:")

        NavigationLink(value: ArticleType.recommendations) {
            NumberedListItem(number: 1) {
                Text("Recommendations")
                    .foregroundStyle(.accent)
            }
        }

        NavigationLink(value: ArticleType.pairingCamera) {
            NumberedListItem(number: 2) {
                Text("Pairing")
                    .foregroundStyle(.accent)
            }
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        ConnectingCameraArticle()
    }
    .padding()
}
