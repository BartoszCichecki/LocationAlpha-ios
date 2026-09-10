//
//  DeviceView.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 03/12/2024.
//

import SwiftUI

struct DeviceView<BottomContent: View, AccessoryContent: View>: View {
    let name: String
    let displayName: String?
    let batteryLevel: UInt8?
    let quickConnect: Bool
    @ViewBuilder let accessory: () -> AccessoryContent
    @ViewBuilder let bottom: () -> BottomContent

    init(device: Device,
         quickConnect: Bool,
         @ViewBuilder accessory: @escaping () -> AccessoryContent,
         @ViewBuilder bottom: @escaping () -> BottomContent)
    {
        self.init(name: device.name ?? "Camera",
                  displayName: device.displayName,
                  batteryLevel: device.batteryLevel,
                  quickConnect: quickConnect,
                  accessory: accessory,
                  bottom: bottom)
    }

    init(knownDevice: KnownDevice,
         @ViewBuilder accessory: @escaping () -> AccessoryContent,
         @ViewBuilder bottom: @escaping () -> BottomContent)
    {
        self.init(name: knownDevice.name ?? "Camera",
                  displayName: knownDevice.displayName,
                  batteryLevel: nil,
                  quickConnect: knownDevice.quickConnect,
                  accessory: accessory,
                  bottom: bottom)
    }

    init(name: String,
         displayName: String?,
         batteryLevel: UInt8?,
         quickConnect: Bool,
         @ViewBuilder accessory: @escaping () -> AccessoryContent,
         @ViewBuilder bottom: @escaping () -> BottomContent)
    {
        self.name = name
        self.displayName = displayName
        self.batteryLevel = batteryLevel
        self.quickConnect = quickConnect
        self.accessory = accessory
        self.bottom = bottom
    }

    var body: some View {
        HStack {
            ZStack {
                Image(systemName: "camera")
                if quickConnect {
                    Image(systemName: "bolt.fill")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.white)
                        .frame(width: 8, height: 8)
                        .padding(1)
                        .background {
                            Circle()
                                .foregroundStyle(.accent)
                        }
                        .offset(x: 8, y: 6)
                }
            }
            VStack(alignment: .leading) {
                if let displayName {
                    if displayName != name {
                        Text(name)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Text(displayName)
                } else {
                    Text(name)
                }
                if let batteryLevel {
                    Text("Battery: \(batteryLevel)%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                bottom()
            }
            Spacer()
            accessory()
        }
        .frame(minHeight: 48)
    }
}

#Preview {
    DeviceView(name: "ILCE-6700",
               displayName: "Sony A6700",
               batteryLevel: 100,
               quickConnect: true)
    {
        EmptyView()
    } bottom: {
        EmptyView()
    }
    DeviceView(name: "ILCE-6700",
               displayName: nil,
               batteryLevel: 100,
               quickConnect: true)
    {
        EmptyView()
    } bottom: {
        EmptyView()
    }
}
