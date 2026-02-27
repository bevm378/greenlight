//
//  CardContainer.swift
//  Greenlight
//
//  Created by keckuser on 2/27/26.
//

import SwiftUI

struct CardContainer<Content: View> : View {
    private let tint: Color?
    private let content: Content

    init(tint: Color? = nil, @ViewBuilder content: () -> Content) {
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .overlay {
                        if let tint {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(tint.opacity(0.06))
                        }
                    }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color(.separator).opacity(0.15))
            )
    }
}
