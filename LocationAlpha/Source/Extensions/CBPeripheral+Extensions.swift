//
//  CBPeripheral+Extensions.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 12/11/2024.
//

import CoreBluetooth
import OrderedCollections

extension CBPeripheral {
    var displayName: String? {
        guard let name, let displayName = CBPeripheral.supportedPeripherals[name] else {
            return name
        }
        return displayName
    }
}

private extension CBPeripheral {
    static let supportedPeripherals: OrderedDictionary<String, String> = [
        "ILCE-1M2": "Sony α1 II",
        "ILCE-1": "Sony α1",
        "ILCE-9M3": "Sony α9 III",
        "ILCE-9M2": "Sony α9 II",
        "ILCE-9": "Sony α9",
        "ILCE-7RM5": "Sony α7R V",
        "ILCE-7RM4": "Sony α7R IV",
        "ILCE-7RM4A": "Sony α7R IV",
        "ILCE-7RM3": "Sony α7R III",
        "ILCE-7RM3A": "Sony α7R III",
        "ILCE-7RM2": "Sony α7R II",
        "ILCE-7SM3": "Sony α7S III",
        "ILCE-7M4": "Sony α7 IV",
        "ILCE-7M3": "Sony α7 III",
        "ILCE-7CR": "Sony α7CR",
        "ILCE-7CM2": "Sony α7C II",
        "ILCE-7C": "Sony α7C",
        "ILCE-6100": "Sony α6100",
        "ILCE-6400": "Sony α6400",
        "ILCE-6500": "Sony α6500",
        "ILCE-6600": "Sony α6600",
        "ILCE-6700": "Sony α6700",
        "ZV-E1": "Sony ZV-E1",
        "ZV-E10M2": "Sony ZV-E10 II",
        "ZV-1M2": "Sony ZV-1 II",
        "ZV-1F": "Sony ZV-1F",
        "ILME-FX3": "Sony FX3",
        "ILME-FX30": "Sony FX30",
    ]
}
