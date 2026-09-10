//
//  AppState.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 17/11/2024.
//

import Combine
import CoreBluetooth
import Observation
import StoreKit

@MainActor @Observable class AppState {
    enum Action {
        case connectAndPair(device: Device)
        case preconnect
        case resumeLocation
        case cleanUp
    }

    var enabled = true {
        didSet {
            guard oldValue != enabled else { return }
            service?.enabled = enabled
        }
    }

    var setupComplete = false {
        didSet {
            guard oldValue != setupComplete else { return }
            service?.setupComplete = setupComplete
        }
    }

    var notifications = false {
        didSet {
            guard oldValue != notifications else { return }
            service?.notifications = notifications
        }
    }

    var locationPauseDelay = LocationPauseDelay.fiveMinutes {
        didSet {
            guard oldValue != locationPauseDelay else { return }
            service?.locationPauseDelay = locationPauseDelay
        }
    }

    var locationHistoryLength: LocationHistoryLength = .week {
        didSet {
            guard oldValue != locationHistoryLength else { return }
            service?.locationHistoryLength = locationHistoryLength
        }
    }

    var appColorScheme = AppColorScheme.system {
        didSet {
            guard oldValue != appColorScheme else { return }
            service?.appColorScheme = appColorScheme
        }
    }

    private(set) var devicesState: DevicesState = .unknown
    private(set) var devices: [Device] = []
    private(set) var knownDevices: [KnownDevice] = []
    private(set) var locationState: LocationState = .notDetermined
    private(set) var location: Location?
    private(set) var hasActiveSubscription = false

    private var service: Service?
    private var cancellables: [AnyCancellable] = []

    init(service: Service) {
        self.service = service

        service.$enabled
            .sink { [weak self] in self?.enabled = $0 }
            .store(in: &cancellables)
        service.$setupComplete
            .sink { [weak self] in self?.setupComplete = $0 }
            .store(in: &cancellables)
        service.$locationPauseDelay
            .sink { [weak self] in self?.locationPauseDelay = $0 }
            .store(in: &cancellables)
        service.$locationHistoryLength
            .sink { [weak self] in self?.locationHistoryLength = $0 }
            .store(in: &cancellables)
        service.$notifications
            .sink { [weak self] in self?.notifications = $0 }
            .store(in: &cancellables)
        service.$appColorScheme
            .sink { [weak self] in self?.appColorScheme = $0 }
            .store(in: &cancellables)
        service.deviceService.$state
            .sink { [weak self] in self?.devicesState = $0 }
            .store(in: &cancellables)
        service.deviceService.$devices
            .sink { [weak self] in self?.devices = $0.map(\.value) }
            .store(in: &cancellables)
        service.deviceService.$knownDevices
            .sink { [weak self] in self?.knownDevices = $0.map(\.value) }
            .store(in: &cancellables)
        service.locationService.$state
            .sink { [weak self] in self?.locationState = $0 }
            .store(in: &cancellables)
        service.locationService.$location
            .sink { [weak self] in self?.location = $0 }
            .store(in: &cancellables)
    }

    init(enabled: Bool = true,
         devicesState: DevicesState = .poweredOn,
         devices: [Device] = [],
         locationState: LocationState = .always(stationary: false),
         location: Location? = nil)
    {
        self.enabled = enabled
        self.devicesState = devicesState
        self.devices = devices
        self.locationState = locationState
        self.location = location
    }

    func set(phase: AppPhase) {
        service?.phase = phase
    }

    func onAction(_ action: Action) {
        switch action {
        case let .connectAndPair(device):
            service?.deviceService.connectAndPair(device: device)
        case .preconnect:
            service?.deviceService.preconnect()
        case .resumeLocation:
            service?.resumeLocation()
        case .cleanUp:
            service?.cleanUp()
        }
    }

    func refreshSubscriptionStatus() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case let .verified(transaction) = result else { continue }
            guard transaction.productType == .autoRenewable, transaction.revocationDate == nil else { continue }
            active = true
            break
        }
        hasActiveSubscription = active
    }
}
