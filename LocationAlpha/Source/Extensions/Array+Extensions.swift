//
//  Array+Extensions.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 09/12/2024.
//

extension [Device] {
    var anyDeviceConnected: Bool {
        !filter { $0.state == .connected }.isEmpty
    }
}
