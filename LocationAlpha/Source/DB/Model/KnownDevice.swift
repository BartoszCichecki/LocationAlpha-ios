//
//  KnownDevice.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 21/11/2024.
//

import Foundation
import SwiftData

@Model public class KnownDevice {
    @Attribute(.unique) var identifier: UUID
    var name: String?
    var displayName: String?
    var quickConnect: Bool
    var lastSeen: Date

    init(identifier: UUID, name: String?, displayName: String?, quickConnect: Bool, lastSeen: Date) {
        self.identifier = identifier
        self.name = name
        self.displayName = displayName
        self.quickConnect = quickConnect
        self.lastSeen = lastSeen
    }
}
