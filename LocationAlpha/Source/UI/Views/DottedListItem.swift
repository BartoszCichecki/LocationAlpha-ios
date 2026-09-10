//
//  DottedListItem.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 19/11/2024.
//

import SwiftUI

struct DottedListItem<Content: View>: View {
    let content: () -> Content

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Circle()
                .foregroundStyle(.accent)
                .frame(width: 8, height: 8)
                .offset(y: -2)
            content()
        }
        .padding(.leading, 4)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        DottedListItem {
            Text("Lorem ipsum lorem ipsum lorem ipsum lorem ipsum")
        }
        DottedListItem {
            Text("Lorem ipsum lorem")
        }
    }
}
