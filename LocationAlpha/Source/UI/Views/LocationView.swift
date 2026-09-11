//
//  LocationView.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 13/11/2024.
//

import MapKit
import SwiftUI

struct LocationView: View {
    @Binding var isPresented: Bool

    let location: Location?
    let deviceConnected: Bool

    var body: some View {
        Map(interactionModes: .init(arrayLiteral: [.pan, .zoom])) {
            if let location {
                MapCircle(center: location.clLocationCoordinate2D,
                          radius: 50)
                    .foregroundStyle(.clear)
                    .mapOverlayLevel(level: .aboveRoads)

                MapCircle(center: location.clLocationCoordinate2D,
                          radius: location.accuracy)
                    .foregroundStyle(.accent.opacity(0.25))
                    .mapOverlayLevel(level: .aboveRoads)

                Annotation(coordinate: location.clLocationCoordinate2D) {
                    if deviceConnected {
                        Image(systemName: "camera")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.white)
                            .frame(width: 16, height: 16)
                            .background {
                                Circle()
                                    .foregroundStyle(.accent)
                                    .frame(width: 32, height: 32)
                            }
                    } else {
                        Circle()
                            .foregroundStyle(.accent)
                            .frame(width: 32, height: 32)
                    }
                } label: {
                    EmptyView()
                }
            }
        }
        .mapStyle(.hybrid(elevation: .automatic, pointsOfInterest: .excludingAll, showsTraffic: false))
        .contentMargins([.bottom], 64)
        .overlay(alignment: .bottom) {
            Button {
                isPresented = false
            } label: {
                Text("Dismiss")
                    .foregroundStyle(.primary)
                    .bold()
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .adaptiveGlassProminentButtonStyle()
            .padding(.horizontal, 32)
        }
    }
}

#Preview("Connected") {
    LocationView(isPresented: .constant(true),
                 location: .init(latitude: 55.67,
                                 longitude: 12.56,
                                 altitude: 0,
                                 accuracy: 50,
                                 timestamp: .now),
                 deviceConnected: true)
}

#Preview("Not connected") {
    LocationView(isPresented: .constant(true),
                 location: .init(latitude: 55.67,
                                 longitude: 12.56,
                                 altitude: 0,
                                 accuracy: 50,
                                 timestamp: .now),
                 deviceConnected: false)
}
