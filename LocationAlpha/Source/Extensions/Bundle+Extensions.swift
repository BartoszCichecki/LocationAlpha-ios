//
//  Bundle+Extensions.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 14/11/2024.
//

import Foundation

extension Bundle {
    var releaseVersionNumber: String {
        infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var buildVersionNumber: String {
        infoDictionary?["CFBundleVersion"] as? String ?? ""
    }
}
