//
//  Double+Extensions.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 12/11/2024.
//

import Foundation

extension Double {
    public enum Orienation {
        case latitude
        case longitude
    }

    func formatted(orientation: Orienation) -> String? {
        let absValue = abs(self)
        let degrees = Int(absValue)
        let minutesDecimal = (absValue - Double(degrees)) * 60
        let minutes = Int(minutesDecimal)
        let seconds = Int(((minutesDecimal - Double(minutes)) * 60).rounded())

        let suffix: String
        switch orientation {
        case .latitude: suffix = self >= 0 ? "N" : "S"
        case .longitude: suffix = self >= 0 ? "E" : "W"
        }

        return String(format: "%d° %d′ %d″ %@", degrees, minutes, seconds, suffix)
    }

    func formatted(unitLength: UnitLength) -> String {
        Measurement(value: self, unit: unitLength).formatted()
    }
}
