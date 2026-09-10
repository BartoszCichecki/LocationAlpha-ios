//
//  URL+Extensions.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 12/11/2024.
//

import Foundation
import UIKit

extension URL {
    static var appSettings: URL? {
        .init(string: UIApplication.openSettingsURLString)
    }
}

extension URL {
    @MainActor func open() {
        if UIApplication.shared.canOpenURL(self) {
            UIApplication.shared.open(self)
        }
    }
}

extension URL? {
    @MainActor func open() {
        if let url = self, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
