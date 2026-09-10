//
//  ArticleType.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 17/11/2024.
//

enum ArticleType: Int, Identifiable {
    case recommendations
    case pairingCamera
    case connectingCamera
    case supportedCameras
    case location

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .recommendations: "Recommendations"
        case .pairingCamera: "Pairing"
        case .connectingCamera: "Connecting"
        case .supportedCameras: "Supported cameras"
        case .location: "Location"
        }
    }
}
