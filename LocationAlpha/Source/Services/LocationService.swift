//
//  LocationService.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 24/10/2024.
//

import Combine
import CoreLocation
import OSLog

enum LocationState: Equatable {
    case notDetermined
    case denied
    case deniedGlobally
    case accuracyLimited
    case always(stationary: Bool)
    case paused
}

struct Location {
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let accuracy: Double
    let timestamp: Date

    init?(location: CLLocation?) {
        guard let location else {
            return nil
        }

        self.init(latitude: location.coordinate.latitude,
                  longitude: location.coordinate.longitude,
                  altitude: location.altitude,
                  accuracy: location.horizontalAccuracy,
                  timestamp: location.timestamp)
    }

    init(latitude: Double, longitude: Double, altitude: Double, accuracy: Double, timestamp: Date) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.accuracy = accuracy
        self.timestamp = timestamp
    }
}

extension Location {
    var clLocationCoordinate2D: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }

    var clLocation: CLLocation {
        .init(latitude: latitude, longitude: longitude)
    }
}

@MainActor class LocationService: ObservableObject {
    private let logger = Logger(category: "LocationService")

    @Published private(set) var state: LocationState = .notDetermined
    @Published private(set) var location: Location?

    private var backgroundSession: CLBackgroundActivitySession?
    private var service: CLServiceSession?

    private var updateTask: Task<Void, any Error>?

    func start() {
        logger.info("Starting...")

        if backgroundSession == nil {
            backgroundSession = CLBackgroundActivitySession()
        }

        service = CLServiceSession(authorization: .always)

        resume()

        logger.info("Started")
    }

    func stop() {
        logger.info("Stopping...")

        pause()

        service?.invalidate()
        service = nil

        backgroundSession?.invalidate()
        backgroundSession = nil

        state = .notDetermined
        location = nil

        logger.info("Stopped")
    }

    func resume() {
        logger.info("Resuming...")

        state = .notDetermined
        location = nil

        updateTask?.cancel()
        updateTask = nil

        updateTask = Task { @MainActor [weak self] in
            guard let self else { return }

            logger.info("Requesting updates...")

            for try await update in CLLocationUpdate.liveUpdates(.otherNavigation) {
                let lat = update.location?.coordinate.latitude
                let lon = update.location?.coordinate.longitude
                let acc = update.location?.horizontalAccuracy

                logger.info("""
                Location updated: \(lat ?? 0.0, privacy: .private(mask: .hash)), \(lon ?? 0.0, privacy: .private(mask: .hash)), \(acc ?? 0.0, privacy: .public), \
                st:\(update.stationary ? "1" : "0", privacy: .public), \
                lu:\(update.locationUnavailable ? "1" : "0", privacy: .public), \
                ssr:\(update.serviceSessionRequired ? "1" : "0", privacy: .public), \
                iiu:\(update.insufficientlyInUse ? "1" : "0", privacy: .public), \
                adg:\(update.authorizationDeniedGlobally ? "1" : "0", privacy: .public), \
                ad:\(update.authorizationDenied ? "1" : "0", privacy: .public), \
                ar:\(update.authorizationRestricted ? "1" : "0", privacy: .public), \
                al:\(update.accuracyLimited ? "1" : "0", privacy: .public), \
                arip:\(update.authorizationRequestInProgress ? "1" : "0", privacy: .public)
                """)

                guard !Task.isCancelled else {
                    return
                }

                state = update.locationState
                location = .init(location: update.location)
            }
        }

        logger.info("Resumed")
    }

    func pause() {
        logger.info("Pausing...")

        updateTask?.cancel()
        updateTask = nil

        state = .paused
        location = nil

        logger.info("Paused")
    }
}

private extension CLLocationUpdate {
    var locationState: LocationState {
        if authorizationDeniedGlobally {
            return .deniedGlobally
        }

        if authorizationDenied {
            return .denied
        }

        if accuracyLimited {
            return .accuracyLimited
        }

        return .always(stationary: stationary)
    }
}
