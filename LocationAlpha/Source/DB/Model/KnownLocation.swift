//
//  KnownLocation.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 06/12/2024.
//

import CoreLocation
import Foundation
import SwiftData

@Model public class KnownLocation {
    static var end: KnownLocation {
        .init(latitude: 0,
              longitude: 0,
              altitude: 0,
              timestamp: .now,
              deviceConnected: false,
              end: true)
    }

    var latitude: Double
    var longitude: Double
    var altitude: Double
    var timestamp: Date
    var deviceConnected: Bool
    var end: Bool

    convenience init(latitude: Double,
                     longitude: Double,
                     altitude: Double,
                     timestamp: Date,
                     deviceConnected: Bool)
    {
        self.init(latitude: latitude,
                  longitude: longitude,
                  altitude: altitude,
                  timestamp: timestamp,
                  deviceConnected: deviceConnected,
                  end: false)
    }

    private init(latitude: Double,
                 longitude: Double,
                 altitude: Double,
                 timestamp: Date,
                 deviceConnected: Bool,
                 end: Bool)
    {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.timestamp = timestamp
        self.deviceConnected = deviceConnected
        self.end = end
    }
}

extension KnownLocation {
    var clLocationCoordinate2D: CLLocationCoordinate2D {
        .init(latitude: latitude, longitude: longitude)
    }

    func distance(from location: KnownLocation) -> Double {
        let this = CLLocation(latitude: latitude, longitude: longitude)
        let other = CLLocation(latitude: location.latitude, longitude: location.longitude)
        return this.distance(from: other)
    }
}
