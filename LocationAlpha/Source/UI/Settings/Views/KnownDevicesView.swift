//
//  KnownDevicesView.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 21/11/2024.
//

import SwiftData
import SwiftUI

struct KnownDevicesView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \KnownDevice.lastSeen, order: .reverse) var knownDevices: [KnownDevice]

    var body: some View {
        List {
            Section {
                ForEach(knownDevices) { device in
                    @Bindable var device = device
                    DeviceView(knownDevice: device) {
                        Toggle(isOn: $device.quickConnect) {
                            EmptyView()
                        }
                        .onChange(of: device.quickConnect) { _, _ in
                            try? modelContext.save()
                            appState.onAction(.preconnect)
                        }
                        .tint(.accentColor)
                    } bottom: {
                        Text("Last connected \(device.lastSeen.formatted(.relative(presentation: .numeric, unitsStyle: .wide)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete { indexes in
                    withAnimation {
                        for index in indexes {
                            modelContext.delete(knownDevices[index])
                        }
                    }
                    try? modelContext.save()

                    appState.onAction(.preconnect)
                }
            } header: {
                if !knownDevices.isEmpty {
                    Text("Quick Connect")
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            } footer: {
                if !knownDevices.isEmpty {
                    Text("Disable Quick Connect, if you enabled \"Connect while Power Off\" on your camera. Keeping this option enabled results in a faster connection.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if knownDevices.isEmpty {
                ContentUnavailableView {
                    Label("No cameras", systemImage: "")
                } description: {
                    Text("Cameras that connect to LocationAlpha will appear here.")
                }
            }
        }
        .navigationTitle("Manage Cameras")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview("Default") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: KnownDevice.self, configurations: config)

    for i in 1 ..< 5 {
        let user = KnownDevice(identifier: UUID(),
                               name: "Device \(i)",
                               displayName: "DeviceX \(i)",
                               quickConnect: true,
                               lastSeen: .now)
        container.mainContext.insert(user)
    }

    return NavigationStack {
        KnownDevicesView()
            .environment(AppState())
            .modelContainer(container)
    }
}

#Preview("Empty") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: KnownDevice.self, configurations: config)

    return NavigationStack {
        KnownDevicesView()
            .environment(AppState())
            .modelContainer(container)
    }
}
