//
//  SpinnerView.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 14/11/2024.
//

import SwiftUI

struct SpinnerView: View {
    @State var animate = true

    var body: some View {
        ZStack {
            if animate {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
        .onAppear {
            animate = true
        }
        .onDisappear {
            animate = false
        }
    }
}

#Preview {
    SpinnerView()
}
