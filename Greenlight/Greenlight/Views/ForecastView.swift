//
//  ForecastView.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/19/26.
//

import SwiftUI

struct ForecastView: View {
    // MARK: - Inputs
    let city: City
    let onChangeCity: (() -> Void)?
    
    // MARK: - UI State
    @State private var isLoading = false
    @State private var forecast: ForecastResponse? = nil
    @State private var errorMessage: String? = nil
    
    // MARK: - Date Formatting
    
    // parse API dates like "2026-02-19"
    private static let apiDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .iso8601)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
    
    // display dates like "Thu, Feb 19"
    private static let displayDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = "EEE, MMM d"
        return df
    }()
    
    // MARK: - Verdict Types
    private enum VerdictLevel {
        case green, yellow, red
        
        var title: String {
            switch self {
            case .green: return "Go"
            case .yellow: return "Caution"
            case .red: return "Stop"
            }
        }
        
        var color: Color {
            switch self {
            case .green: return .green
            case .yellow: return .yellow
            case .red: return .red
            }
        }
    }
    
    private struct Verdict {
        let level: VerdictLevel
        let feelsLikeLine: String
        let rainLine: String
        let windLine: String
        let whyLine: String
        let recommendation: String
    }
    
    // MARK: - Body
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {

                // loading state
                if isLoading {
                    HStack { Spacer(); ProgressView(); Spacer() }
                        .padding(.top, 12)
                }
                
                // error state
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .font(.footnote)
                        .padding(.horizontal)
                }

                // loaded state
                if let forecast {
                    let i = 0
                    let todayVerdict = makeVerdict(
                        feelsLikeHighF: forecast.daily.apparent_temperature_max[safe: i],
                        feelsLikeLowF: forecast.daily.apparent_temperature_min[safe: i],
                        popMax: forecast.daily.precipitation_probability_max?[safe: i],
                        rainInches: forecast.daily.rain_sum?[safe: i],
                        windMph: forecast.daily.wind_speed_10m_max?[safe: i]
                    )

                    verdictCard(todayVerdict)
                        .padding(.top, 8)

                    Text("Daily Forecast")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 4)

                    forecastList(forecast)
                        .padding(.horizontal)
                }
            }
            .padding(.bottom, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("\(city.name), \(city.admin1 ?? city.country)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let onChangeCity {
                Button("Change city") { onChangeCity() }
            }
        }
        .task { await loadForecast() }
    }
    
    // MARK: - Networking
    @MainActor
    private func loadForecast() async {
        isLoading = true
        forecast = nil
        errorMessage = nil
        
        do {
            forecast = try await getForecast(lat: city.latitude, lon: city.longitude)
        } catch {
            print("Forecast failed:", error)
            forecast = nil
            errorMessage = "Couldn’t load forecast right now."
        }
        
        isLoading = false
    }
    
    // MARK: - Verdict Logic
    
    // convert forecast numbers into the verdict text shown in the verdict card
    private func makeVerdict(
        feelsLikeHighF: Double?,
        feelsLikeLowF: Double?,
        popMax: Int?,
        rainInches: Double?,
        windMph: Double?
    ) -> Verdict {
        
        let hi = feelsLikeHighF
        let lo = feelsLikeLowF
        
        // temperature flags
        var tempLevel: VerdictLevel? = nil
        if let hi {
            if hi <= 25 { tempLevel = .red }
            else if hi <= 40 { tempLevel = .yellow }
        }
        if let lo, lo <= 25, tempLevel != .red { tempLevel = .yellow }
        
        // rain flags
        var rainLevel: VerdictLevel? = nil
        if let rain = rainInches, rain >= 0.50 { rainLevel = .red }
        else if (rainInches ?? 0) >= 0.10 || (popMax ?? 0) >= 40 { rainLevel = .yellow }
        
        // wind flags
        var windLevel: VerdictLevel? = nil
        if let wind = windMph, wind >= 25 { windLevel = .red }
        else if let wind = windMph, wind >= 15 { windLevel = .yellow }
        
        // overall verdict: any red -> red; else any yellow -> yellow; else green
        let level: VerdictLevel = {
            if tempLevel == .red || rainLevel == .red || windLevel == .red { return .red }
            if tempLevel == .yellow || rainLevel == .yellow || windLevel == .yellow { return .yellow }
            return .green
        }()
        
        // detail lines shown in verdict card
        let feelsLikeLine: String = {
            if let hi, let lo { return "Feels like \(Int(lo.rounded())) – \(Int(hi.rounded()))°F" }
            if let hi { return "Feels like ~\(Int(hi.rounded()))°F" }
            return "Feels like unavailable"
        }()
        
        let rainLine = popMax.map { "Precipitation \($0)%" } ?? "Precipitation unavailable"
        let windLine = windMph.map { "Wind \(Int($0.rounded())) mph" } ?? "Wind unavailable"
        let whyLine: String = {
            switch level {
            case .green:
                return "Ideal conditions"
            case .yellow:
                if tempLevel == .yellow { return "Chilly" }
                if rainLevel == .yellow { return "Light rain" }
                if windLevel == .yellow { return "Breezy" }
                return "Less-than-ideal conditions"
            case .red:
                if tempLevel == .red { return "Frigid" }
                if rainLevel == .red { return "Heavy rain" }
                if windLevel == .red { return "Windy" }
                return "Harsh conditions"
            }
        }()
        
        let recommendation: String = {
            switch level {
            case .green:
                return "It's great outside, so enjoy a nice walk!"
            case .yellow:
                if tempLevel == .yellow { return "It's fine outside, but add a warm layer" }
                if rainLevel == .yellow { return "It's fine outside, but bring a rain layer" }
                if windLevel == .yellow { return "It's fine outside, but stick to sheltered routes" }
                return "It's fine outside, but keep plans flexible"
            case .red:
                return "It's better to stay indoors today"
            }
        }()
        
        return Verdict(
            level: level,
            feelsLikeLine: feelsLikeLine,
            rainLine: rainLine,
            windLine: windLine,
            whyLine: whyLine,
            recommendation: recommendation
        )
    }
    
    // MARK: - UI Helpers
    private func prettyDate(_ apiDate: String) -> String {
        guard let d = Self.apiDateFormatter.date(from: apiDate) else { return apiDate }
        return Self.displayDateFormatter.string(from: d)
    }
    
    private func labelRow(system: String, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: system)
                .imageScale(.medium)
                .frame(width: 22, alignment: .leading)
                .foregroundStyle(.secondary)
            
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func verdictCard(_ verdict: Verdict) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Circle()
                    .fill(verdict.level.color)
                    .frame(width: 14, height: 14)

                Text(verdict.level.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .lineLimit(1)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 6) {
                labelRow(system: "thermometer", text: verdict.feelsLikeLine)
                labelRow(system: "cloud.rain", text: verdict.rainLine)
                labelRow(system: "wind", text: verdict.windLine)
                labelRow(system: "sparkles", text: verdict.whyLine)
            }
            .font(.body)
            .foregroundStyle(.secondary)

            Text(verdict.recommendation)
                .font(.headline)
                .padding(.top, 2)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(verdict.level.color.opacity(0.08))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.separator).opacity(0.18))
        )
        .padding(.horizontal)
        .padding(.top, 4)
    }
    
    private func forecastList(_ forecast: ForecastResponse) -> some View {
        VStack(spacing: 0) {
            ForEach(forecast.daily.time.indices, id: \.self) { idx in
                forecastRow(
                    dateText: prettyDate(forecast.daily.time[idx]),
                    hi: forecast.daily.temperature_2m_max[idx],
                    lo: forecast.daily.temperature_2m_min[idx],
                    pop: forecast.daily.precipitation_probability_max?[safe: idx]
                )

                if idx != forecast.daily.time.indices.last {
                    Divider()
                        .opacity(0.6)
                        .padding(.leading, 12)
                }
            }
        }
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.separator).opacity(0.15))
        )
    }
    
    private func forecastRow(dateText: String, hi: Double, lo: Double, pop: Int?) -> some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 0) {
            GridRow {
                // date
                Text(dateText)
                    .lineLimit(1)
                    .frame(minWidth: 120, alignment: .leading)
                    .gridColumnAlignment(.leading)
                                
                // high / low
                Text("H \(Int(hi.rounded()))°  L \(Int(lo.rounded()))°")
                    .font(.body.monospacedDigit())
                    .lineLimit(1)
                    .frame(width: 120, alignment: .leading)
                    .gridColumnAlignment(.leading)
                
                // precipitation %
                HStack(spacing: 6) {
                    Image(systemName: "umbrella.fill")
                        .font(.caption)
                    Text(pop.map { "\($0)%" } ?? "--")
                        .font(.body.monospacedDigit())
                }
                .foregroundStyle(.secondary)
                .frame(width: 70, alignment: .leading)
                .gridColumnAlignment(.leading)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }    
}

// MARK: - Safe Indexing
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ForecastView(city: City(
        id: 1,
        name: "Secaucus",
        latitude: 40.7895,
        longitude: -74.0565,
        country: "United States",
        country_code: "US",
        admin1: "New Jersey",
        population: nil,
        timezone: nil
    ), onChangeCity: nil)
}
