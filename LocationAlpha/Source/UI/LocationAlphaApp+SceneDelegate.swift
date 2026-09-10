//
//  LocationAlphaApp+SceneDelegate.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 15/11/2024.
//

import Combine
import UIKit

class SceneDelegate: NSObject, UIWindowSceneDelegate {
    @UserDefault(\.appColorScheme) var appColorScheme = AppColorScheme.system

    private var cancellables: Set<AnyCancellable> = []

    override init() {
        super.init()

        $appColorScheme
            .sink { [weak self] in self?.applyAppColorScheme($0) }
            .store(in: &cancellables)
    }

    func scene(_ scene: UIScene, willConnectTo _: UISceneSession, options _: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else {
            return
        }

        for window in windowScene.windows {
            window.overrideUserInterfaceStyle = UserDefaults.standard.appColorScheme.userInterfaceStyle
        }
    }
}

private extension SceneDelegate {
    func applyAppColorScheme(_ appColorScheme: AppColorScheme) {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .forEach {
                $0.overrideUserInterfaceStyle = appColorScheme.userInterfaceStyle
            }
    }
}
