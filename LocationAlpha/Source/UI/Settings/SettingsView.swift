//
//  SettingsView.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 13/11/2024.
//

import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.modelContext) private var modelContext

    @State var isKnownDevicesOpen = false
    @State var isClearHistoryConfirmationOpen = false
    @State var isLogOpen = false
    @State var debugModeTapCount = 0

    @DebugModeState var debugMode

    var body: some View {
        List {
            @Bindable var appState = appState
            Section {
                Picker(selection: $appState.appColorScheme) {
                    Text("System")
                        .tag(AppColorScheme.system)
                    Text("Light")
                        .tag(AppColorScheme.alwaysLight)
                    Text("Dark")
                        .tag(AppColorScheme.alwaysDark)
                } label: {
                    Text("Appearance")
                }
                Toggle(isOn: $appState.notifications) {
                    Text("Notifications")
                }
                .tint(.accentColor)
            } header: {
                Text("General")
            } footer: {
                Text("LocationAlpha will notify you when a camera connects or disconnects.")
            }

            Section {
                Button {
                    isKnownDevicesOpen.toggle()
                } label: {
                    HStack {
                        Text("Manage Cameras")
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(.tertiary)
                    }
                }
                .foregroundStyle(.primary)
            } header: {
                Text("Cameras")
            } footer: {
                Text("Manage cameras that previously connected to LocationAlpha.")
            }

            Section {
                Picker(selection: $appState.locationPauseDelay) {
                    Text("30 seconds")
                        .tag(LocationPauseDelay.thirtySeconds)
                    Text("2 minutes")
                        .tag(LocationPauseDelay.twoMinutes)
                    Text("5 minutes")
                        .tag(LocationPauseDelay.fiveMinutes)
                    Text("10 minutes")
                        .tag(LocationPauseDelay.tenMinutes)
                    Text("15 minutes")
                        .tag(LocationPauseDelay.fifteenMinutes)
                    Text("30 minutes")
                        .tag(LocationPauseDelay.thirtyMinutes)
                    Text("1 hour")
                        .tag(LocationPauseDelay.oneHour)
                } label: {
                    Text("Pause after")
                }
                Picker(selection: $appState.locationHistoryLength) {
                    Text("24 hours")
                        .tag(LocationHistoryLength.day)
                    Text("1 week")
                        .tag(LocationHistoryLength.week)
                    Text("1 month")
                        .tag(LocationHistoryLength.month)
                    Text("3 months")
                        .tag(LocationHistoryLength.quarter)
                } label: {
                    Text("Keep for")
                }
                Button {
                    isClearHistoryConfirmationOpen.toggle()
                } label: {
                    Text("Clear History")
                }
                .confirmationDialog("Clear History",
                                    isPresented: $isClearHistoryConfirmationOpen,
                                    titleVisibility: .visible)
                {
                    Button(role: .destructive) {
                        try? modelContext.delete(model: KnownLocation.self)
                        try? modelContext.save()
                    } label: {
                        Text("Clear")
                    }
                }
            } header: {
                Text("Location")
            } footer: {
                Text("Location tracking will automatically pause when no camera is connected to preseve energy after specified time.")
            }

            Section {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("\(Bundle.main.releaseVersionNumber) (\(Bundle.main.buildVersionNumber))")
                        .foregroundStyle(.secondary)
                        .onTapGesture {
                            guard !debugMode else {
                                return
                            }

                            debugModeTapCount += 1

                            if debugModeTapCount >= 20 {
                                debugModeTapCount = .min
                                debugMode = true
                                UINotificationFeedbackGenerator().notificationOccurred(.success)
                            }
                        }
                }
                Link(destination: URL(string: "https://locationalpha.com/support/")!) {
                    HStack {
                        Text("Support")
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                    }
                }
                Link(destination: URL(string: "https://locationalpha.com/privacy-policy/")!) {
                    HStack {
                        Text("Privacy Policy")
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                    }
                }
                Link(destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!) {
                    HStack {
                        Text("Terms of Use")
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                    }
                }
            } header: {
                Text("About")
            } footer: {
                Text("Made with love ❤️ in 🇵🇱 & 🇩🇰.")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            }

            if debugMode {
                Section {
                    Button("Disable Debug Mode") {
                        debugMode.toggle()
                    }
                    Button("Open Log") {
                        isLogOpen.toggle()
                    }
                    Button("Force Crash") {
                        fatalError("Force Crash")
                    }
                    Button("Show Setup") {
                        appState.setupComplete = false
                    }
                } header: {
                    Text("Debug")
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationDestination(isPresented: $isKnownDevicesOpen) {
            KnownDevicesView()
        }
        .sheet(isPresented: $isLogOpen) {
            NavigationStack {
                LogView(isPresented: $isLogOpen)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppState())
    }
}
