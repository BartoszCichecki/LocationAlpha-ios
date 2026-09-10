//
//  LocationArticle.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 09/12/2024.
//

import SwiftUI

struct LocationArticle: View {
    var body: some View {
        Text("LocationAlpha tracks your location automatically. Tracking begins when you open the app or when you connect a camera. After a period of time when no cameras are connected location tracking stops.")

        Text("You can use this feature to track your photo shoots, in 3 simple steps:")

        NumberedListItem(number: 1) {
            Text("Open LocationAlpha or turn on your camera")
        }

        NumberedListItem(number: 2) {
            Text("Shoot photos. Run, hike, move around - you can turn your camera off and on in the meantime")
        }

        NumberedListItem(number: 3) {
            Text("After a period of time when your camera is off, tracking stops.")
        }

        Text("Each location session like the one above is stored in History and can be exported from this app to a GPX file.")

        Text("Check Settings to customize how long the tracking works in the background and how long this data is kept. You can also clear all location history from Settings.")

        Text("Location data is stored on your device and is not shared with anyone or anything, except your cameras.")
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 16) {
        LocationArticle()
    }
    .padding()
}
