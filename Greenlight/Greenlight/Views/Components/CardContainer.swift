//
//  CardContainer.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/27/26.
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
            .background(cardBackground)
            .overlay(cardBorder)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color(.secondarySystemGroupedBackground))
            .overlay {
                if let tint {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(tint.opacity(0.06))
                }
            }
    }
         
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 14)
            .stroke(Color(.separator).opacity(0.15))
    }
}
