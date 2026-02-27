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
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                
                // header
                VStack(alignment: .leading, spacing: 6) {
                    Text(cityName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(dateText)
                        .font(.title2.weight(.semibold))
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                VStack(alignment: .leading, spacing: 10) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        metricChip("High", "\(Int(hi.rounded()))°")
                        metricChip("Low", "\(Int(lo.rounded()))°")
                        metricChip("Precip", pop.map { "\($0)%" } ?? "--")
                        metricChip("Wind", wind.map { "\(Int($0.rounded())) mph" } ?? "--")
                    }
                    if let rain {
                        Text("Rain total: \(String(format: "%.2f", rain)) in")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(.secondarySystemGroupedBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(.separator).opacity(0.15))
                )
                .padding(.horizontal)
                
                Spacer(minLength: 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(dateText)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func metricChip(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.body.monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
