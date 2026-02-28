//
//  MetricChip.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/27/26.
//

import SwiftUI

struct MetricChip<Trailing: View>: View {
    let label: String
    let value: String
    var tint: Color? = nil
    @ViewBuilder var trailing: () -> Trailing

    init(_ label: String, _ value: String, tint: Color? = nil,
         @ViewBuilder trailing: @escaping () -> Trailing) {
        self.label = label
        self.value = value
        self.tint = tint
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(value)
                    .font(.body.monospacedDigit())
            }
            
            Spacer(minLength: 0)
            trailing()
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .fill((tint ?? .clear).opacity(0.08))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke((tint ?? Color(.separator)).opacity(tint == nil ? 0.15 : 0.18))
        )
    }
}

extension MetricChip where Trailing == EmptyView {
    init(_ label: String, _ value: String, tint: Color? = nil) {
        self.init(label, value, tint: tint) { EmptyView() }
    }
}
