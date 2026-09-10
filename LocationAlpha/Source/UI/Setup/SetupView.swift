//
//  SetupView.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 13/11/2024.
//

import SwiftUI

struct SetupView: View {
    enum Step {
        case welcome
        case notification
        case bluetooth
        case locationWhenInUse
        case locationAlways
        case finished
    }

    @State var finished: () -> Void
    @State var currentStep: Step = .welcome

    var body: some View {
        VStack {
            steps
                .transition(.asymmetric(insertion: .move(edge: .trailing),
                                        removal: .move(edge: .leading)))
        }
        .animation(.default, value: currentStep)
    }

    @ViewBuilder private var steps: some View {
        switch currentStep {
        case .welcome:
            WelcomeSetupStepView {
                currentStep = .notification
            }
        case .notification:
            NotificationSetupStep {
                currentStep = .bluetooth
            }
        case .bluetooth:
            BluetoothSetupStep {
                currentStep = .locationWhenInUse
            }
        case .locationWhenInUse:
            LocationWhileUsingSetupStep {
                currentStep = $0 ? .locationAlways : .finished
            }
        case .locationAlways:
            LocationAlwaysSetupStep {
                currentStep = .finished
            }
        case .finished:
            FinishedSetupStep {
                finished()
            }
        }
    }
}

#Preview {
    SetupView {}
}
