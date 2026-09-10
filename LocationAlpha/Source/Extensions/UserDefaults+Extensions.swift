//
//  UserDefaults+Extensions.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 12/11/2024.
//

import Combine
import Foundation

extension UserDefaults {
    @objc dynamic var setupComplete: Bool {
        get { bool(forKey: .settingSetupComplete) }
        set { setValue(newValue, forKey: .settingSetupComplete) }
    }

    @objc dynamic var enabled: Bool {
        get { bool(forKey: .settingEnabled) }
        set { setValue(newValue, forKey: .settingEnabled) }
    }

    @objc dynamic var appColorScheme: AppColorScheme {
        get { AppColorScheme(rawValue: integer(forKey: .settingAppColorScheme)) ?? .system }
        set { setValue(newValue.rawValue, forKey: .settingAppColorScheme) }
    }

    @objc dynamic var notifications: Bool {
        get { bool(forKey: .settingNotifications) }
        set { setValue(newValue, forKey: .settingNotifications) }
    }

    @objc dynamic var locationPauseDelay: LocationPauseDelay {
        get { LocationPauseDelay(rawValue: integer(forKey: .locationPauseDelay)) ?? .fiveMinutes }
        set { setValue(newValue.rawValue, forKey: .locationPauseDelay) }
    }

    @objc dynamic var locationHistoryLength: LocationHistoryLength {
        get { LocationHistoryLength(rawValue: integer(forKey: .locationHistoryLength)) ?? .week }
        set { setValue(newValue.rawValue, forKey: .locationHistoryLength) }
    }
}

extension UserDefaults {
    func registerDefaults() {
        register(defaults: [
            .settingSetupComplete: false,
            .settingEnabled: true,
            .settingAppColorScheme: AppColorScheme.system.rawValue,
            .settingNotifications: true,
            .locationPauseDelay: LocationPauseDelay.fiveMinutes.rawValue,
            .locationHistoryLength: LocationHistoryLength.week.rawValue,
        ])
    }
}

@propertyWrapper
struct UserDefault<T> where T: Equatable {
    private let _keyPath: ReferenceWritableKeyPath<UserDefaults, T>
    private let _userDefaults: UserDefaults

    public var wrappedValue: T {
        get {
            _userDefaults[keyPath: _keyPath]
        }
        set {
            _userDefaults[keyPath: _keyPath] = newValue
        }
    }

    public var projectedValue: AnyPublisher<T, Never> {
        _userDefaults.publisher(for: _keyPath)
            .receive(on: RunLoop.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    public init(wrappedValue _: T, _ keyPath: ReferenceWritableKeyPath<UserDefaults, T>, userDefaults: UserDefaults = .standard) {
        _keyPath = keyPath
        _userDefaults = userDefaults
    }
}

private extension String {
    static let settingSetupComplete = "setupComplete"
    static let settingEnabled = "enabled"
    static let settingAppColorScheme = "appColorScheme"
    static let settingNotifications = "notifications"
    static let locationPauseDelay = "locationPauseDelay"
    static let locationHistoryLength = "locationHistoryLength"
}
