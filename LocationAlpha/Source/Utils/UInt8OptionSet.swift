//
//  UInt8OptionSet.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 16/11/2024.
//

struct UInt8OptionSet: OptionSet {
    let rawValue: UInt8

    static let bit0 = UInt8OptionSet(rawValue: 1 << 0)
    static let bit1 = UInt8OptionSet(rawValue: 1 << 1)
    static let bit2 = UInt8OptionSet(rawValue: 1 << 2)
    static let bit3 = UInt8OptionSet(rawValue: 1 << 3)
    static let bit4 = UInt8OptionSet(rawValue: 1 << 4)
    static let bit5 = UInt8OptionSet(rawValue: 1 << 5)
    static let bit6 = UInt8OptionSet(rawValue: 1 << 6)
    static let bit7 = UInt8OptionSet(rawValue: 1 << 7)
}
