//
//  Data+Extensions.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 02/12/2024.
//

import Foundation

extension Data {
    var hexString: String {
        "[\(map(\.hexString).joined(separator: ","))]"
    }
}
