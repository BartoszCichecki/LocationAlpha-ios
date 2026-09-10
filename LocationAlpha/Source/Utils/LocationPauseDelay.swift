//
//  LocationPauseDelay.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 24/11/2024.
//

import Foundation

@objc enum LocationPauseDelay: Int {
    case thirtySeconds = 30
    case twoMinutes = 120
    case fiveMinutes = 300
    case tenMinutes = 600
    case fifteenMinutes = 900
    case thirtyMinutes = 1800
    case oneHour = 3600
}

extension LocationPauseDelay {
    var timeInterval: TimeInterval {
        TimeInterval(rawValue)
    }
}
