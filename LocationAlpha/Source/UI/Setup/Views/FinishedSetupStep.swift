//
//  FinishedSetupStep.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 14/11/2024.
//

import SwiftUI

struct FinishedSetupStep: View {
    @State var next: () -> Void

    var body: some View {
        SetupStep(image: Image(systemName: "checkmark.seal.fill"),
                  title: "You are all set!",
                  subtitle: "You are now ready to start using LocationAlpha.",
                  button: "Done",
                  next: next)
    }
}

#Preview {
    FinishedSetupStep {}
}
