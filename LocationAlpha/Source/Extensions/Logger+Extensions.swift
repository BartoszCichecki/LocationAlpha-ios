//
//  Logger+Extensions.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 02/12/2024.
//

import OSLog

extension Logger {
    init(category: String) {
        self.init(subsystem: "LocationAlpha", category: category)
    }
}
