//
//  DayDetailView.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/26/26.
//

import SwiftUI

struct DayDetailView: View {
    let cityName: String
    let dateText: String
    let hi: Double
    let lo: Double
    let pop: Int?
    let wind: Double?
    let rain: Double?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {

                Text(cityName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(dateText)
                    .font(.title2.weight(.semibold))

                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        metricChip("High", "\(Int(hi.rounded()))°")
                        metricChip("Low", "\(Int(lo.rounded()))°")
                    }
                    GridRow {
                        metricChip("Precip", pop.map { "\($0)%" } ?? "--")
                        metricChip("Wind", wind.map { "\(Int($0.rounded())) mph" } ?? "--")
                    }
                }
                .padding(.top, 6)

                if let rain {
                    Text("Rain total: \(String(format: "%.2f", rain)) in")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Day details")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }

    private func metricChip(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.monospacedDigit())
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.15))
        )
    }
}

#Preview {
    NavigationStack {
        DayDetailView(
            cityName: "Los Angeles, California",
            dateText: "Thu, Feb 26",
            hi: 83,
            lo: 53,
            pop: 0,
            wind: 8,
            rain: 0.00
        )
    }
}
