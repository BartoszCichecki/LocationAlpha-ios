//
//  CameraPairingData.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 12/11/2024.
//

import Foundation

struct CameraPairingData {
    let withDisconnect: Bool

    init(withDisconnect: Bool) {
        self.withDisconnect = withDisconnect
    }

    var data: Data {
        Data([0x6, 0x8, withDisconnect ? 0x2 : 0x1, 0x0, 0x0, 0x0])
    }
}
