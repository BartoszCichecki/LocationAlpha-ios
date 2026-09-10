//
//  HelpView.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 14/11/2024.
//

import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    @State var presentedArticle: ArticleType?
    @State var isPresented = false

    var body: some View {
        List {
            Section {
                NavigationLink(value: ArticleType.recommendations) {
                    Text(ArticleType.recommendations.title)
                }
                NavigationLink(value: ArticleType.supportedCameras) {
                    Text(ArticleType.supportedCameras.title)
                }
            } header: {
                Text("General")
            }

            Section {
                NavigationLink(value: ArticleType.pairingCamera) {
                    Text(ArticleType.pairingCamera.title)
                }
                NavigationLink(value: ArticleType.connectingCamera) {
                    Text(ArticleType.connectingCamera.title)
                }
            } header: {
                Text("Camera")
            }

            Section {
                NavigationLink(value: ArticleType.location) {
                    Text(ArticleType.location.title)
                }
            } header: {
                Text("Location")
            }

            Section {
                EmailFeedbackButton()
            } header: {
                Text("Feedback")
            } footer: {
                Text("Mail app must be configured on your phone to share feedback.")
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Help")
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(item: $presentedArticle) { articleType in
            ArticleView(article: articleType)
        }
        .navigationDestination(for: ArticleType.self) { articleType in
            ArticleView(article: articleType)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isPresented {
                    HStack {
                        Button("Close", systemImage: "xmark") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        HelpView()
    }
}
