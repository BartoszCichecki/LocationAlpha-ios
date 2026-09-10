//
//  SetupStep.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 14/11/2024.
//

import SwiftUI

struct SetupStep: View {
    @State var image: Image
    @State var title: String
    @State var subtitle: String
    @State var infoText: String? = nil
    @State var button: String

    @State var next: () async -> Void

    @State var moreInfoButton: String? = nil
    @State var moreInfo: (() async -> Void)? = nil

    @State private var isRunning = false

    var body: some View {
        VStack {
            ZStack {
                VStack {
                    Color.clear
                        .overlay(alignment: .bottom) {
                            image
                                .resizable()
                                .scaledToFit()
                                .foregroundStyle(.white)
                                .frame(width: 64, height: 64)
                                .padding(24)
                                .foregroundStyle(.primary)
                                .background {
                                    LinearGradient.accent
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                }
                                .glassEffect(in: RoundedRectangle(cornerRadius: 16))
                                .padding(.bottom, 32)
                        }

                    Text(title)
                        .multilineTextAlignment(.center)
                        .font(.title)
                        .foregroundStyle(.primary)
                        .bold()

                    Color.clear
                        .overlay(alignment: .top) {
                            Text(subtitle)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.darkDarkGray)
                        }
                        .overlay(alignment: .bottom) {
                            VStack {
                                if let infoText {
                                    HStack(alignment: .center) {
                                        Image(systemName: "info.bubble")
                                        Text(infoText)
                                            .multilineTextAlignment(.leading)
                                            .font(.callout)
                                    }
                                    .foregroundStyle(.secondary)
                                    .padding(.bottom, 16)
                                }
                                if let moreInfoButton, let moreInfo {
                                    Button {
                                        Task {
                                            await moreInfo()
                                        }
                                    } label: {
                                        Text(moreInfoButton)
                                            .font(.callout)
                                    }
                                    .padding(.bottom, 16)
                                }
                            }
                        }
                }
            }

            Button {
                isRunning = true
                Task {
                    await next()
                    isRunning = false
                }
            } label: {
                Text(button)
                    .bold()
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.glassProminent)
            .disabled(isRunning)
        }
        .padding(.horizontal, 32)
    }
}

#Preview {
    SetupStep(image: .init(systemName: "checkmark"),
              title: "Title",
              subtitle: "Subtitle",
              infoText: "Info info info info info info info info info info info info info info info info",
              button: "Button",
              next: {},
              moreInfoButton: "More info",
              moreInfo: {})
}
