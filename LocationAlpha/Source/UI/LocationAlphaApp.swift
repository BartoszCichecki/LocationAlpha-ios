//
//  LocationAlphaApp.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 24/10/2024.
//

import SwiftUI

@main
struct LocationAlphaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @Environment(\.scenePhase) private var scenePhase

    @State var appState = AppState(service: Service.shared)

    var body: some Scene {
        WindowGroup {
            Group {
                if !appState.setupComplete {
                    SetupView {
                        appState.setupComplete = true
                    }
                } else {
                    TabView {
                        NavigationStack {
                            MainView()
                        }
                        .tag("home")
                        .tabItem {
                            Label("Home", systemImage: "house")
                        }

                        NavigationStack {
                            KnownLocationsView()
                        }
                        .tag("history")
                        .tabItem { Label("History", systemImage: "calendar") }

                        NavigationStack {
                            HelpView()
                        }
                        .tag("help")
                        .tabItem { Label("Help", systemImage: "questionmark.circle") }

                        NavigationStack {
                            SettingsView()
                        }
                        .tag("settings")
                        .tabItem { Label("Settings", systemImage: "gear") }
                    }
                }
            }
            .animation(.easeInOut, value: appState.setupComplete)
            .environment(appState)
            .modelContainer(for: [KnownDevice.self, KnownLocation.self])
            .task {
                await appState.refreshSubscriptionStatus()
            }
            .onChange(of: scenePhase) { _, newScenePhase in
                switch newScenePhase {
                case .background:
                    appState.set(phase: .background)
                    appState.onAction(.resumeLocation)
                case .active:
                    appState.set(phase: .active)
                    appState.onAction(.cleanUp)
                    Task { await appState.refreshSubscriptionStatus() }
                case .inactive:
                    appState.set(phase: .inactive)
                @unknown default:
                    break
                }
            }
        }
    }
}
