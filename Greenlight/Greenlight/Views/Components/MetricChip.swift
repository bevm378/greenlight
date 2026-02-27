//
//  MetricChip.swift
//  Greenlight
//
//  Created by keckuser on 2/27/26.
//

import SwiftUI

struct MetricChip: View {
    let label: String
    let value: String
    var tint: Color? = nil

    init(_ label: String, _ value: String, tint: Color? = nil) {
        self.label = label
        self.value = value
        self.tint = tint
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.body.monospacedDigit())
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
