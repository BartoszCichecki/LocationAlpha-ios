//
//  UInt8+Extensions.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 16/11/2024.
//

extension UInt8 {
    var hexString: String {
        .init(format: "%02X", self)
    }
}

extension UInt8 {
    var optionSet: UInt8OptionSet {
        .init(rawValue: self)
    }
}
