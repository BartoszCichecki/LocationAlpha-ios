//
//  LocationSection.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 13/11/2024.
//

import SwiftUI

struct LocationSection: View {
    @Binding var isLocationOpen: Bool

    let enabled: Bool
    let state: LocationState
    let location: Location?
    let deviceConnected: Bool
    let resumeLocation: () -> Void

    var body: some View {
        if enabled {
            Section {
                content
            } header: {
                header
            } footer: {
                footer
            }
            .onChange(of: state) { _, newState in
                let closeMap = switch newState {
                case .always, .accuracyLimited, .notDetermined: false
                case .paused, .denied, .deniedGlobally: true
                }

                guard closeMap else {
                    return
                }

                isLocationOpen = false
            }
        }
    }

    private var header: some View {
        Text("Location")
    }

    @ViewBuilder private var content: some View {
        switch state {
        case .always(stationary: _): locationContent
        case .accuracyLimited: locationContent
        case .paused: pausedContent
        case .denied: disabledContent
        case .deniedGlobally: disabledContent
        case .notDetermined: waitingForLocationContent
        }
    }

    @ViewBuilder private var footer: some View {
        switch state {
        case let .always(stationary): locationFooter(stationary: stationary)
        case .accuracyLimited: needsPreciseLocationFooter
        case .paused: pausedFooter
        case .denied: deniedFooter
        case .deniedGlobally: deniedGloballyFooter
        case .notDetermined: EmptyView()
        }
    }

    @ViewBuilder private var locationContent: some View {
        if let location {
            HStack {
                Text("Position")
                Spacer()
                VStack {
                    Text(location.latitude.formatted(orientation: .latitude) ?? "-")
                        .foregroundStyle(.secondary)
                    Text(location.longitude.formatted(orientation: .longitude) ?? "-")
                        .foregroundStyle(.secondary)
                }
            }
            HStack {
                Text("Accuracy")
                Spacer()
                if location.accuracy > 0 {
                    Text(location.accuracy.formatted(unitLength: .meters))
                        .foregroundStyle(.secondary)
                } else {
                    Text("-")
                        .foregroundStyle(.secondary)
                }
            }
            Button {
                isLocationOpen.toggle()
            } label: {
                HStack {
                    Text("Show on map")
                    Spacer()
                    Image(systemName: "mappin.and.ellipse")
                }
            }
        } else {
            waitingForLocationContent
        }
    }

    private var pausedContent: some View {
        HStack {
            Button {
                resumeLocation()
            } label: {
                HStack {
                    Text("Paused")
                    Spacer()
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }

    private var waitingForLocationContent: some View {
        HStack {
            Text("Finding location...")
                .foregroundStyle(.secondary)
            Spacer()
            SpinnerView()
        }
    }

    private var disabledContent: some View {
        HStack {
            Button {
                URL.appSettings.open()
            } label: {
                Text("Location is disabled")
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.accent)
        }
    }

    @ViewBuilder private func locationFooter(stationary: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if let timestamp = location?.timestamp {
                if stationary {
                    Text("Location tracking will resume when you start moving.")
                } else {
                    Text("Last updated: \(timestamp.formatted(date: .abbreviated, time: .standard))")
                }
            }

            Text("If you want to location tracking to work in background, Location access should be set to \"Always\". [Tap here](action://) to verify settings.")
                .environment(\.openURL, OpenURLAction(handler: { _ in
                    URL.appSettings.open()
                    return .handled
                }))
        }
    }

    private var needsPreciseLocationFooter: some View {
        Text("For best experience, LocationAlpha needs access to precise location of your device. [Tap here](action://) to verify settings.")
            .environment(\.openURL, OpenURLAction(handler: { _ in
                URL.appSettings.open()
                return .handled
            }))
    }

    private var pausedFooter: some View {
        Text("Location tracking is paused and will automatically resume when a camera connects.")
    }

    private var deniedFooter: some View {
        Text("LocationAlpha needs access to precise location of your device. [Tap here](action://) to verify settings.")
            .environment(\.openURL, OpenURLAction(handler: { _ in
                URL.appSettings.open()
                return .handled
            }))
    }

    private var deniedGloballyFooter: some View {
        Text("Location Services are disabled.")
    }
}

#Preview("Default") {
    List {
        LocationSection(isLocationOpen: .constant(false),
                        enabled: true,
                        state: .always(stationary: false),
                        location: .init(latitude: 55.67,
                                        longitude: 12.56,
                                        altitude: 0,
                                        accuracy: 500,
                                        timestamp: .now),
                        deviceConnected: true,
                        resumeLocation: {})
    }
}

#Preview("Default") {
    List {
        LocationSection(isLocationOpen: .constant(false),
                        enabled: true,
                        state: .paused,
                        location: nil,
                        deviceConnected: true,
                        resumeLocation: {})
    }
}
