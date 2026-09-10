//
//  Service.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 24/10/2024.
//

import Combine
import CoreLocation
import Foundation
import OSLog

@MainActor class Service: ObservableObject {
    private let logger = Logger(category: "Service")

    static var shared = Service()

    @UserDefault(\.enabled) var enabled = false
    @UserDefault(\.setupComplete) var setupComplete = false
    @UserDefault(\.notifications) var notifications = true
    @UserDefault(\.locationPauseDelay) var locationPauseDelay = LocationPauseDelay.fiveMinutes
    @UserDefault(\.locationHistoryLength) var locationHistoryLength: LocationHistoryLength = .week
    @UserDefault(\.appColorScheme) var appColorScheme: AppColorScheme = .system

    @Published var phase: AppPhase = .background

    let database: Database
    let locationService: LocationService
    let deviceService: DeviceService

    private let timer = Timer.publish(every: 10, on: .main, in: .default)
        .autoconnect()
        .prepend(Date.now)

    private let resumeLocationSubject = CurrentValueSubject<Void, Never>(())

    private var initCancellables: Set<AnyCancellable> = []
    private var cancellables: Set<AnyCancellable> = []

    private var cameraWasConnected = false

    private init() {
        logger.info("Initializing...")

        UserDefaults.standard.registerDefaults()

        database = try! Database()
        locationService = LocationService()
        deviceService = DeviceService(database: database)

        Publishers.CombineLatest($enabled, $setupComplete)
            .removeDuplicates { old, new in
                old.0 == new.0 && old.1 == new.1
            }
            .sink { [weak self] enabled, setupComplete in
                guard let self else { return }
                stop()

                guard enabled, setupComplete else {
                    return
                }

                start()
            }
            .store(in: &initCancellables)

        logger.info("Initialized")
    }

    public func resumeLocation() {
        resumeLocationSubject.send()
    }

    public func cleanUp() {
        try? database.cleanUp(locationHistoryLength: locationHistoryLength)
    }

    private func start() {
        logger.info("Starting...")

        // Location updates
        Publishers.CombineLatest3(locationService.$location, deviceService.$devices, timer)
            .filter(\.1.anyDeviceConnected)
            .compactMap(\.0)
            .throttle(for: .seconds(5), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] in
                guard let self else { return }

                logger.info("Sending location data...")

                deviceService.write(location: $0,
                                    date: Date.now,
                                    timeZone: .current)
            }
            .store(in: &cancellables)

        // Location history
        locationService.$location
            .compactMap(\.self)
            .throttle(for: .seconds(15), scheduler: RunLoop.main, latest: true)
            .withPrevious()
            .filter { [weak self] in
                guard let self else {
                    return false
                }

                guard let previous = $0.previous else {
                    return true
                }

                let distance = previous.clLocation.distance(from: $0.current.clLocation)
                let allow = distance > 10

                if !allow {
                    logger.info("Rejecting location data - distance: \(distance) meters...")
                } else {
                    logger.info("Allowing location data - distance: \(distance) meters...")
                }

                return allow
            }
            .compactMap(\.current)
            .sink { [weak self] in
                guard let self else { return }

                logger.info("Saving location data \($0.timestamp)...")

                try? database.insert(.init(location: $0,
                                           deviceConnected: deviceService.devices.anyDeviceConnected))
            }
            .store(in: &cancellables)

        // Battery level updates
        Publishers.CombineLatest(deviceService.$devices, timer)
            .filter(\.0.anyDeviceConnected)
            .throttle(for: .seconds(15), scheduler: RunLoop.main, latest: true)
            .sink { [weak self] _ in
                guard let self else { return }

                logger.info("Reading battery level...")

                deviceService.readBatteryLevel()
            }
            .store(in: &cancellables)

        // Notifications - device connects
        Publishers.CombineLatest(deviceService.connected, $notifications)
            .filter(\.1)
            .map(\.0)
            .sink { [weak self] in
                guard let self else {
                    return
                }

                Notifications.notifyDevice(connected: $0)

                cameraWasConnected = true
            }
            .store(in: &cancellables)

        // Notifications - device disconnects
        Publishers.CombineLatest(deviceService.disconnected, $notifications)
            .filter(\.1)
            .map(\.0)
            .sink {
                Notifications.notifyDevice(disconnected: $0)
            }
            .store(in: &cancellables)

        // Notifications - location
        Publishers.CombineLatest(locationService.$state, $notifications)
            .filter(\.1)
            .map(\.0)
            .sink { [weak self] in
                guard let self else {
                    return
                }

                if $0 == .paused {
                    if cameraWasConnected {
                        Notifications.notifyPaused()
                    }

                    cameraWasConnected = false
                } else {
                    Notifications.notifyResumed()
                }
            }
            .store(in: &cancellables)

        // Resume location - trigger
        resumeLocationSubject
            .sink { [weak self] in
                guard let self else {
                    return
                }

                guard locationService.state == .paused else {
                    return
                }

                locationService.resume()
            }
            .store(in: &cancellables)

        // Resume location - inactivity
        Publishers.CombineLatest3($phase, deviceService.$devices, resumeLocationSubject)
            .map { [weak self] phase, devices, _ in
                if phase != .background {
                    Just(true)
                        .eraseToAnyPublisher()
                } else if devices.anyDeviceConnected {
                    Just(true)
                        .eraseToAnyPublisher()
                } else {
                    Just(false)
                        .delay(for: .seconds(self?.locationPauseDelay.timeInterval ?? 30.0), scheduler: RunLoop.main)
                        .eraseToAnyPublisher()
                }
            }
            .switchToLatest()
            .receive(on: RunLoop.main)
            .sink { [weak self] in
                guard let self else { return }

                guard $0 else {
                    logger.info("Pausing location...")

                    try? database.insert(KnownLocation.end)

                    locationService.pause()
                    return
                }

                if locationService.state == .paused {
                    logger.info("Resuming location...")
                    locationService.resume()
                }
            }
            .store(in: &cancellables)

        locationService.start()
        deviceService.start()

        logger.info("Started")
    }

    private func stop() {
        logger.info("Stopping...")

        try? database.insert(KnownLocation.end)

        locationService.stop()
        deviceService.stop()

        cancellables = []

        logger.info("Stopped")
    }
}

private extension KnownLocation {
    convenience init(location: Location, deviceConnected: Bool) {
        self.init(latitude: location.latitude,
                  longitude: location.longitude,
                  altitude: location.altitude,
                  timestamp: location.timestamp,
                  deviceConnected: deviceConnected)
    }
}
