//
//  View+GlassEffect.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 11/09/2026.
//

import SwiftUI

extension View {
    @ViewBuilder
    func adaptiveGlassEffect() -> some View {
        if #available(iOS 26, *) {
            glassEffect()
        } else {
            background(.regularMaterial, in: Capsule())
        }
    }

    @ViewBuilder
    func adaptiveGlassEffect(in shape: some Shape) -> some View {
        if #available(iOS 26, *) {
            glassEffect(in: shape)
        } else {
            background(.regularMaterial, in: shape)
        }
    }

    @ViewBuilder
    func adaptiveGlassEffect(tint: Color) -> some View {
        if #available(iOS 26, *) {
            glassEffect(.regular.tint(tint))
        } else {
            background(tint, in: Capsule())
        }
    }

    @ViewBuilder
    func adaptiveGlassProminentButtonStyle() -> some View {
        if #available(iOS 26, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }
}
