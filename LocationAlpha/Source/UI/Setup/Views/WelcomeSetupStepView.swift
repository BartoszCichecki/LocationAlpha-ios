//
//  WelcomeSetupStepView.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 14/11/2024.
//

import SwiftUI

struct WelcomeSetupStepView: View {
    @State var next: () -> Void
    @State var isPresented = false

    var body: some View {
        SetupStep(image: Image("cameraLocation"),
                  title: "Welcome to LocationAlpha!",
                  subtitle: "Let's start with setting up required permissions.",
                  button: "Get started",
                  next: next,
                  moreInfoButton: "Which cameras are supported?",
                  moreInfo: { isPresented = true })
            .sheet(isPresented: $isPresented) {
                NavigationStack {
                    ArticleView(article: .supportedCameras, isPresented: true)
                }
            }
    }
}

#Preview {
    WelcomeSetupStepView {}
}
