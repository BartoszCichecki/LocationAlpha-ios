//
//  MainView.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 24/10/2024.
//

import StoreKit
import SwiftUI

struct MainView: View {
    @Environment(AppState.self) private var appState

    @State private var helpArticleOpen: ArticleType?
    @State private var isLocationOpen = false
    @State private var isManageSubscriptionsOpen = false

    var body: some View {
        List {
            if appState.hasActiveSubscription {
                subscriptionCancellationSection
            }

            enableSection

            DevicesSection(helpArticleOpen: $helpArticleOpen,
                           enabled: appState.enabled,
                           state: appState.devicesState,
                           devices: appState.devices,
                           knownDevices: appState.knownDevices)
            {
                appState.onAction(.connectAndPair(device: $0))
            }

            LocationSection(isLocationOpen: $isLocationOpen,
                            enabled: appState.enabled,
                            state: appState.locationState,
                            location: appState.location,
                            deviceConnected: appState.devices.anyDeviceConnected)
            {
                appState.onAction(.resumeLocation)
            }
        }
        .animation(.default, value: appState.enabled)
        .animation(.default, value: appState.hasActiveSubscription)
        .listStyle(.insetGrouped)
        .sheet(item: $helpArticleOpen) { _ in
            NavigationStack {
                HelpView(presentedArticle: helpArticleOpen, isPresented: true)
            }
        }
        .sheet(isPresented: $isLocationOpen) {
            LocationView(isPresented: $isLocationOpen,
                         location: appState.location,
                         deviceConnected: appState.devices.anyDeviceConnected)
                .presentationDetents([.medium])
        }
        .manageSubscriptionsSheet(isPresented: $isManageSubscriptionsOpen)
        .navigationTitle("LocationAlpha")
        .navigationBarTitleDisplayMode(.large)
    }

    private var subscriptionCancellationSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("🎉 It's on the house!")
                    .font(.headline)
                Text("LocationAlpha is now **free** — no subscription needed. Cancel yours and keep enjoying all features.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Button {
                    isManageSubscriptionsOpen = true
                } label: {
                    Text("Cancel Subscription")
                        .bold()
                        .frame(maxWidth: .infinity, minHeight: 28)
                }
                .adaptiveGlassProminentButtonStyle()
                .padding(.top, 4)
            }
            .padding(.vertical, 4)
        }
    }

    private var enableSection: some View {
        Section {
            @Bindable var appState = appState
            Toggle(isOn: $appState.enabled) {
                Text("Enable")
            }
            .tint(.accentColor)
        } header: {
            Spacer()
        } footer: {
            if !appState.enabled {
                Text("LocationAlpha will no longer connect to your camera or track your location.")
            }
        }
    }
}

#Preview("Default") {
    TabView(selection: .constant("home")) {
        NavigationStack {
            NavigationStack {
                MainView()
                    .environment(AppState(devices: [
                            .init(identifier: UUID(),
                                  advertisementData: Device.AdvertisementData(from: Data(count: 22))!,
                                  name: "ILCE-6700",
                                  displayName: "Sony α6700",
                                  state: .connected,
                                  batteryLevel: 72),
                        ],
                        location: .init(latitude: 55.67,
                                        longitude: 12.56,
                                        altitude: 0,
                                        accuracy: 50,
                                        timestamp: .now)))
            }
        }
        .tabItem {
            Label("Home", systemImage: "house")
        }

        NavigationStack {
            EmptyView()
        }
        .tag("history")
        .tabItem { Label("History", systemImage: "calendar") }

        NavigationStack {
            EmptyView()
        }
        .tag("help")
        .tabItem { Label("Help", systemImage: "questionmark.circle") }

        NavigationStack {
            EmptyView()
        }
        .tag("settings")
        .tabItem { Label("Settings", systemImage: "gear") }
    }
}

#Preview("Empty") {
    TabView(selection: .constant("home")) {
        NavigationStack {
            MainView()
                .environment(AppState())
        }
        .tabItem {
            Label("Home", systemImage: "house")
        }

        NavigationStack {
            EmptyView()
        }
        .tag("history")
        .tabItem { Label("History", systemImage: "calendar") }

        NavigationStack {
            EmptyView()
        }
        .tag("help")
        .tabItem { Label("Help", systemImage: "questionmark.circle") }

        NavigationStack {
            EmptyView()
        }
        .tag("settings")
        .tabItem { Label("Settings", systemImage: "gear") }
    }
}

#Preview("Many") {
    TabView(selection: .constant("home")) {
        NavigationStack {
            MainView()
                .environment(AppState(devices: [
                        .init(identifier: UUID(),
                              advertisementData: Device.AdvertisementData(from: Data(count: 22))!,
                              name: "ILCE-6700",
                              displayName: "Sony α6700",
                              state: .connected,
                              batteryLevel: 72),
                        .init(identifier: UUID(),
                              advertisementData: Device.AdvertisementData(from: Data(count: 22))!,
                              name: "ZV-E10M2",
                              displayName: "Sony ZV-E10 II",
                              state: .connected,
                              batteryLevel: 22),
                        .init(identifier: UUID(),
                              advertisementData: Device.AdvertisementData(from: Data(count: 22))!,
                              name: "ILCE-7SM3",
                              displayName: "Sony α7S III",
                              state: .connected,
                              batteryLevel: nil),
                    ],
                    location: .init(latitude: 55.67,
                                    longitude: 12.56,
                                    altitude: 0,
                                    accuracy: 50,
                                    timestamp: .now)))
        }
        .tabItem {
            Label("Home", systemImage: "house")
        }

        NavigationStack {
            EmptyView()
        }
        .tag("history")
        .tabItem { Label("History", systemImage: "calendar") }

        NavigationStack {
            EmptyView()
        }
        .tag("help")
        .tabItem { Label("Help", systemImage: "questionmark.circle") }

        NavigationStack {
            EmptyView()
        }
        .tag("settings")
        .tabItem { Label("Settings", systemImage: "gear") }
    }
}

#Preview("Pair") {
    TabView(selection: .constant("home")) {
        NavigationStack {
            MainView()
                .environment(AppState(devices: [
                        .init(identifier: UUID(),
                              advertisementData: Device.AdvertisementData(from: Data(count: 22))!,
                              name: "ILCE-6700",
                              displayName: "Sony α6700",
                              state: .readyToPair,
                              batteryLevel: nil),
                    ],
                    location: .init(latitude: 55.67,
                                    longitude: 12.56,
                                    altitude: 0,
                                    accuracy: 50,
                                    timestamp: .now)))
        }
        .tabItem {
            Label("Home", systemImage: "house")
        }

        NavigationStack {
            EmptyView()
        }
        .tag("history")
        .tabItem { Label("History", systemImage: "calendar") }

        NavigationStack {
            EmptyView()
        }
        .tag("help")
        .tabItem { Label("Help", systemImage: "questionmark.circle") }

        NavigationStack {
            EmptyView()
        }
        .tag("settings")
        .tabItem { Label("Settings", systemImage: "gear") }
    }
}
