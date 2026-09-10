//
//  OrderedDictionary+Extensions.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 18/11/2024.
//

import CoreBluetooth
import OrderedCollections

extension OrderedDictionary where Key == CBPeripheral, Value == Device {
    var anyDeviceConnected: Bool {
        !values.filter { $0.state == .connected }.isEmpty
    }
}
