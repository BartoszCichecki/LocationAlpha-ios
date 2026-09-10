//
//  LocationPermissionHelper.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 14/11/2024.
//

import CoreLocation

@MainActor class LocationPermissionHelper {
    private class Handler: NSObject, CLLocationManagerDelegate {
        var completionHandler: (Bool) -> Void

        init(completionHandler: @escaping (Bool) -> Void) {
            self.completionHandler = completionHandler
        }

        func locationManager(_: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            switch status {
            case .notDetermined:
                break
            case .authorizedAlways:
                completionHandler(true)
            case .authorizedWhenInUse:
                completionHandler(true)
            default:
                completionHandler(false)
            }
        }
    }

    nonisolated static var status: String {
        switch CLLocationManager().authorizationStatus {
        case .notDetermined: "Not Determined"
        case .restricted: "Restricted"
        case .denied: "Denied"
        case .authorizedAlways: "Authorized Always"
        case .authorizedWhenInUse: "Authorized When In Use"
        @unknown default: "Unknown"
        }
    }

    private var manager: CLLocationManager?
    private var handler: Handler?

    @discardableResult func requestPermission(always: Bool) async throws -> Bool {
        await withCheckedContinuation { continuation in
            handler = Handler { [weak self] result in
                guard let self else { return }

                handler = nil
                manager?.delegate = nil
                manager = nil

                continuation.resume(returning: result)
            }

            manager = CLLocationManager()
            manager?.delegate = handler
            if always {
                manager?.requestAlwaysAuthorization()
            } else {
                manager?.requestWhenInUseAuthorization()
            }
        }
    }
}
