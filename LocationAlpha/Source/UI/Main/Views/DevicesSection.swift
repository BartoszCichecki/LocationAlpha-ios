//
//  DevicesSection.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 13/11/2024.
//

import SwiftUI

struct DevicesSection: View {
    @Binding var helpArticleOpen: ArticleType?

    let enabled: Bool
    let state: DevicesState
    let devices: [Device]
    let knownDevices: [KnownDevice]
    let connectAndPair: (Device) -> Void

    var body: some View {
        if enabled {
            Section {
                content
            } header: {
                header
            } footer: {
                footer
            }
        }
    }

    var header: some View {
        Text("Cameras")
    }

    @ViewBuilder var content: some View {
        switch state {
        case .poweredOn: devicesList
        case .poweredOff: poweredOff
        case .unauthorized: unauthorized
        case .resetting: resetting
        case .unsupported: unsupported
        case .unknown: EmptyView()
        @unknown default: EmptyView()
        }
    }

    @ViewBuilder var footer: some View {
        switch state {
        case .poweredOn: howToConnectFooter
        case .poweredOff: poweredOffFooter
        case .unauthorized: unauthorizedFooter
        case .resetting: EmptyView()
        case .unsupported: EmptyView()
        case .unknown: EmptyView()
        @unknown default: EmptyView()
        }
    }

    @ViewBuilder var devicesList: some View {
        if devices.isEmpty {
            HStack {
                Text("Looking for cameras...")
                    .foregroundStyle(.secondary)
                Spacer()
                SpinnerView()
            }
        } else {
            ForEach(devices) { device in
                DeviceView(device: device,
                           quickConnect: knownDevices.contains(where: { $0.identifier == device.identifier }))
                {
                    switch device.state {
                    case .readyToPair:
                        Button("Pair") {
                            connectAndPair(device)
                        }
                    case .pairing:
                        SpinnerView()
                    case .connecting:
                        SpinnerView()
                    case .connected:
                        Text("Connected")
                            .foregroundStyle(.secondary)
                    case .disconnecting:
                        SpinnerView()
                    case .error:
                        EmptyView()
                    }
                } bottom: {
                    if device.state == .connected,
                       device.locationInfoLinkEnabledInSession == false
                    {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .resizable()
                                .foregroundStyle(.accent)
                                .frame(width: 10, height: 10)
                            Text("Location Info Link disabled")
                                .font(.caption)
                                .foregroundStyle(.accent)
                        }
                    }
                }
            }
        }
    }

    var poweredOff: some View {
        Text("Bluetooth is turned off")
            .foregroundStyle(.secondary)
    }

    var unauthorized: some View {
        HStack {
            Button {
                URL.appSettings.open()
            } label: {
                Text("Bluetooth is disabled")
            }
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundStyle(.accent)
        }
    }

    var resetting: some View {
        Text("Bluetooth services are restarting")
            .foregroundStyle(.secondary)
    }

    var unsupported: some View {
        Text("Bluetooth LE is not supported")
            .foregroundStyle(.secondary)
    }

    @ViewBuilder var howToConnectFooter: some View {
        if devices.isEmpty || devices.contains(where: { $0.state == .readyToPair }) {
            Text("How to connect a camera?")
                .foregroundStyle(.accent)
                .onTapGesture {
                    helpArticleOpen = .connectingCamera
                }
        }
    }

    var poweredOffFooter: some View {
        Text("Bluetooth needs to be turned on your phone.")
    }

    var unauthorizedFooter: some View {
        Text("LocationAlpha must be allowed to use Bluetooth.")
    }
}

#Preview {
    List {
        DevicesSection(helpArticleOpen: .constant(nil),
                       enabled: true,
                       state: .poweredOn,
                       devices: [
                           .init(identifier: UUID(),
                                 advertisementData: Device.AdvertisementData(from: Data(count: 22))!,
                                 name: "ILCE-6700",
                                 displayName: "Sony A6700",
                                 state: .readyToPair,
                                 batteryLevel: nil),
                           .init(identifier: UUID(),
                                 advertisementData: Device.AdvertisementData(from: Data(count: 22))!,
                                 name: "ILCE-6700",
                                 displayName: "Sony A6700",
                                 state: .connecting,
                                 batteryLevel: nil),
                           .init(identifier: UUID(),
                                 advertisementData: Device.AdvertisementData(from: Data(count: 22))!,
                                 name: "ILCE-6700",
                                 displayName: "Sony A6700",
                                 state: .connected,
                                 batteryLevel: 75),
                           .init(identifier: UUID(),
                                 advertisementData: Device.AdvertisementData(from: Data(count: 22))!,
                                 name: "Custom name",
                                 displayName: nil,
                                 state: .connected,
                                 batteryLevel: 75),
                           .init(identifier: UUID(),
                                 advertisementData: Device.AdvertisementData(from: Data(count: 22))!,
                                 name: "ZV-E10",
                                 displayName: nil,
                                 state: .connected,
                                 batteryLevel: nil),
                       ],
                       knownDevices: [],
                       connectAndPair: { _ in })
    }
}
