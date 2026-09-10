//
//  DebugMode.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 24/11/2024.
//

import Combine
import Foundation
import SwiftUI

@propertyWrapper
struct DebugMode {
    private let key = "debugMode"

    var wrappedValue: Bool {
        didSet {
            UserDefaults.standard.set(wrappedValue, forKey: key)
        }
    }

    init() {
        wrappedValue = UserDefaults.standard.bool(forKey: key)
    }
}

@propertyWrapper
struct DebugModeState: DynamicProperty {
    @State private var debugMode = DebugMode()

    var wrappedValue: Bool {
        get { debugMode.wrappedValue }
        nonmutating set { debugMode.wrappedValue = newValue }
    }
}
