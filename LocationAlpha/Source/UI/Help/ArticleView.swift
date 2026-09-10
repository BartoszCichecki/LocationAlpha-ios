//
//  ArticleView.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 14/11/2024.
//

import SwiftUI

struct ArticleView: View {
    @Environment(\.dismiss) private var dismiss

    @State var article: ArticleType
    @State var isPresented = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                switch article {
                case .recommendations: RecommendationsArticle()
                case .pairingCamera: PairingCameraArticle()
                case .connectingCamera: ConnectingCameraArticle()
                case .supportedCameras: SupportedCamerasArticle()
                case .location: LocationArticle()
                }
            }
            .padding(16)
        }
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.large)
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

#Preview("Recommendations") {
    NavigationStack {
        ArticleView(article: .recommendations)
    }
}

#Preview("Pairing camera") {
    NavigationStack {
        ArticleView(article: .pairingCamera)
    }
}

#Preview("Connecting camera") {
    NavigationStack {
        ArticleView(article: .connectingCamera)
    }
}

#Preview("Supported cameras") {
    NavigationStack {
        ArticleView(article: .supportedCameras)
    }
}

#Preview("Location") {
    NavigationStack {
        ArticleView(article: .location)
    }
}
