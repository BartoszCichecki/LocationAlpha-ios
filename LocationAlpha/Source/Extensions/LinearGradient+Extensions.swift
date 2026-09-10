//
//  LinearGradient+Extensions.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 13/02/2025.
//

import SwiftUI

extension LinearGradient {
	static let accent: LinearGradient = .init(colors: [.accentColor, .secondaryAccent],
                                              startPoint: .topLeading,
                                              endPoint: .bottomTrailing)
}
