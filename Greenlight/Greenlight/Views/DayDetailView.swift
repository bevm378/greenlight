//
//  DayDetailView.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/26/26.
//

import SwiftUI

struct DayDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let cityName: String
    let dateText: String
    let hi: Double
    let lo: Double
    let pop: Int?
    let wind: Double?
    let rain: Double?
    let verdict: Verdict
    
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
                .padding(.leading)
                
                VStack(alignment: .leading, spacing: 10) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        MetricChip("High", "\(Int(hi.rounded()))°", tint: chipTint(for: verdict.tempLevel))
                        MetricChip("Low", "\(Int(lo.rounded()))°", tint: chipTint(for: verdict.tempLevel))
                        MetricChip("Precip", pop.map { "\($0)%" } ?? "--", tint: chipTint(for: verdict.rainLevel)) 
                        MetricChip("Wind", wind.map { "\(Int($0.rounded())) mph" } ?? "--", tint: chipTint(for: verdict.windLevel))
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
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
    }
}

private let verdictForPreview = Verdict(
    level: .green,
    feelsLikeLine: "Feels like 70° / 55°",
    whyLine: "Clear conditions",
    recommendation: "It's looking great outside!",
    tempLevel: nil,
    rainLevel: nil,
    windLevel: nil
)

#Preview {
    NavigationStack {
        DayDetailView(
            cityName: "Los Angeles, California",
            dateText: "Thu, Feb 26",
            hi: 83,
            lo: 53,
            pop: 0,
            wind: 8,
            rain: 0.00,
            verdict: verdictForPreview
        )
    }
}
