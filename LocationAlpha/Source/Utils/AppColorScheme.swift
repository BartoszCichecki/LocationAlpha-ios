//
//  AppColorScheme.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 15/11/2024.
//

import SwiftUI

@objc enum AppColorScheme: Int, RawRepresentable {
    case system
    case alwaysLight
    case alwaysDark
}

extension AppColorScheme {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .alwaysLight: .light
        case .alwaysDark: .dark
        }
    }
}

extension AppColorScheme {
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .alwaysLight: .light
        case .alwaysDark: .dark
        }
    }
}
