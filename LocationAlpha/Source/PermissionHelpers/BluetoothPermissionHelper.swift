//
//  BluetoothPermissionHelper.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 14/11/2024.
//

import CoreBluetooth

@MainActor class BluetoothPermissionHelper: NSObject {
    private class Handler: NSObject, CBCentralManagerDelegate {
        private let completionHandler: (Bool) -> Void

        init(completionHandler: @escaping (Bool) -> Void) {
            self.completionHandler = completionHandler
        }

        func centralManagerDidUpdateState(_: CBCentralManager) {
            let result = CBCentralManager.authorization == .allowedAlways
            completionHandler(result)
        }
    }

    nonisolated static var status: String {
        switch CBCentralManager.authorization {
        case .allowedAlways: "Allowed Always"
        case .denied: "Denied"
        case .notDetermined: "Not Determined"
        case .restricted: "Restricted"
        @unknown default: "Unknown"
        }
    }

    private var manager: CBCentralManager?
    private var handler: Handler?

    @discardableResult func requestPermission() async throws -> Bool {
        await withCheckedContinuation { continuation in
            handler = Handler { [weak self] status in
                guard let self else { return }

                handler = nil
                manager?.delegate = nil
                manager = nil

                continuation.resume(returning: status)
            }
            manager = CBCentralManager(delegate: handler, queue: .main)
        }
    }
}
