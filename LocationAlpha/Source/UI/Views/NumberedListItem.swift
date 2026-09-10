//
//  NumberedListItem.swift
//  LocationAlpha
//
//  Created by Bartosz Cichecki on 19/11/2024.
//

import SwiftUI

struct NumberedListItem<Content: View>: View {
    let number: Int
    let content: () -> Content

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            ZStack {
                Circle()
                    .foregroundStyle(.accent)
                    .frame(width: 16, height: 16)
                Text("\(number)")
                    .foregroundStyle(.background)
                    .font(.caption)
            }
            .offset(y: -2)
            content()
        }
        .padding(.leading, 4)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 8) {
        NumberedListItem(number: 1) {
            Text("Lorem ipsum lorem ipsum lorem ipsum lorem ipsum")
        }
        NumberedListItem(number: 2) {
            Text("Lorem ipsum lorem")
        }
    }
}
