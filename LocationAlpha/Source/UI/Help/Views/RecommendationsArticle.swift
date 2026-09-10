//
//  RecommendationsArticle.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 14/11/2024.
//

import SwiftUI

struct RecommendationsArticle: View {
    var body: some View {
        Text("Here are some recommendations, to make your experience smooth.")

        Text("Your phone")
            .font(.headline)
            .padding(.top, 16)

        NumberedListItem(number: 1) {
            Text("Turn on Bluetooth")
        }
        NumberedListItem(number: 2) {
            Text("Turn on Location Services")
        }
        NumberedListItem(number: 3) {
            Text("Allow LocationAlpha to access your Location \"Always\" and enable \"Precise location\"")
        }
        NumberedListItem(number: 4) {
            Text("Allow LocationAlpha to use Bluetooth")
        }

        if let appSettings = URL.appSettings {
            Text("You can [tap here](action://) to check these settings.")
                .environment(\.openURL, OpenURLAction(handler: { _ in
                    appSettings.open()
                    return .handled
                }))
                .font(.callout)
                .padding(.top, 8)
        }

        Text("Your camera")
            .font(.headline)
            .padding(.top, 16)

        NumberedListItem(number: 1) {
            Text("Turn on Bluetooth")
        }
        NumberedListItem(number: 2) {
            Text("Turn on Location Info Link")
        }
        NumberedListItem(number: 3) {
            Text("Turn on Auto Time Correct and Auto Area Adjust")
        }

        Text("On most cameras, these settings are in the Network menu. You can skip options that are not available on your camera.")
            .font(.callout)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        RecommendationsArticle()
    }
    .padding()
}
