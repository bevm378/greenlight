//
//  ForecastView.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/19/26.
//

import SwiftUI

struct ForecastView: View {
    let city: City
    
    // UI state
    @State private var isLoading = false
    @State private var forecast: ForecastResponse? = nil
    @State private var errorMessage: String? = nil
    
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
    
    // nice date string
    private func prettyDate(_ apiDate: String) -> String {
        guard let d = Self.apiDateFormatter.date(from: apiDate) else { return apiDate }
        return Self.displayDateFormatter.string(from: d)
    }
    
    // format temps like " 5°" or "10°"
    private func tempString(_ value: Double) -> String {
        String(format: "%2d°", Int(value.rounded()))
    }
    
    // format POP like " 10%" or "100%"
    private func popString(_ value: Int) -> String {
        String(format: "%3d%%", value)
    }
    
    // --- verdict ---
    
    private enum VerdictLevel {
        case green, yellow, red
        var title: String {
            switch self {
            case .green: return "Good day to go outside"
            case .yellow: return "Okay day, but plan around weather"
            case .red: return "Stay indoors"
            }
        }
        var color: Color {
            switch self {
            case .green: return .green
            case .yellow: return .yellow
            case .red: return .red
            }
        }
        
        var emoji: String {
            switch self {
            case .green: return "🟢"
            case .yellow: return "🟡"
            case .red: return "🔴"
            }
        }
    }
    
    private struct Verdict {
        let level: VerdictLevel
        let reason: String
        let recommendation: String
    }
    
    private func makeVerdict(
        feelsLikeHighF: Double?,
        feelsLikeLowF: Double?,
        popMax: Int?,
        rainInches: Double?,
        windMph: Double?
    ) -> Verdict {
        
        // main temp number
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
        
        // any red -> red, else any yellow ->  yellow, else green
        let level: VerdictLevel = {
            if tempLevel == .red || rainLevel == .red || windLevel == .red { return .red }
            if tempLevel == .yellow || rainLevel == .yellow || windLevel == .yellow { return .yellow }
            return .green
        }()
        
        // reason string
        var parts: [String] = []
        
        if let hi, let lo {
            parts.append("Feels like \(Int(lo.rounded()))-\(Int(hi.rounded()))ºF")
        } else if let hi {
            parts.append("Feels like ~\(Int(hi.rounded()))℉")
        }
        
        if let popMax {
            parts.append("Rain chance \(popMax)%")
        } else if let rain = rainInches, rain > 0 {
            parts.append("Rain ~\(String(format: "%.2f", rain)) in")
        }
        
        if let wind = windMph {
            parts.append("Wind \(Int(wind.rounded())) mph")
        }
        
        let reason = parts.isEmpty ? "Not enough data yet" : parts.joined(separator: " • ")
        
        // rec (walking default)
        let recommendation: String = {
            switch level {
            case .green:
                return "Recommended: Walk or run"
            case .yellow:
                // rec based on which caution triggered most
                if rainLevel == .yellow { return "Recommended: Walk between showers" }
                if windLevel == .yellow { return "Recommended: Walk, but avoid super windy routes" }
                if tempLevel == .yellow { return "Recommended: Walk with layers" }
                return "Recommended: Light outdoor workout"
            case .red:
                return "Recommended: Indoor workout"
            }
        }()
        
        return Verdict(level: level, reason: reason, recommendation: recommendation)
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

                Spacer()
            }

            Text(verdict.reason)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(verdict.recommendation)
                .font(.headline)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(.background)
                .shadow(radius: 2, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.quaternary)
        )
        .padding(.horizontal)
        .padding(.top, 4)
    }

    // --- Rows ---
    
    private func forecastRow(dateText: String, hi: Double, lo: Double, pop: Int?) -> some View {
        HStack(spacing: 10) {
            //left: date
            Text(dateText)
                .frame(width: 100, alignment: .leading)
                .lineLimit(1)

            // middle: temps
            HStack(spacing: 6) {
                Text("H \(tempString(hi))")
                Text("L \(tempString(lo))")
                    .foregroundStyle(.secondary)
            }
            .font(.system(.body, design: .monospaced))
            .lineLimit(1)
            .frame(width: 110, alignment: .trailing)

            // right: precip
            HStack(spacing: 6) {
                Image(systemName: "umbrella.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 14, alignment: .center)

                Text(pop.map(popString) ?? "--")
            }
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(.secondary)
            .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 6)
    }

    // --- UI ---
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("\(city.name), \(city.admin1 ?? city.country)")
                .font(.title2)
                .bold()
                .padding(.horizontal)
                .padding(.top, 8)
            
            // loading spinner
            if isLoading {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .padding(.top, 12)
            }

            // error
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
                    .font(.footnote)
                    .padding(.horizontal)
            }
            
            if let forecast {
                // today's verdict
                let i = 0
                let todayVerdict = makeVerdict(
                    feelsLikeHighF: forecast.daily.apparent_temperature_max[safe: i],
                    feelsLikeLowF: forecast.daily.apparent_temperature_min[safe: i],
                    popMax: forecast.daily.precipitation_probability_max?[safe: i],
                    rainInches: forecast.daily.rain_sum?[safe: i],
                    windMph: forecast.daily.wind_speed_10m_max?[safe: i]
                )
                
                // forecast list
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        
                        verdictCard(todayVerdict)
                            .padding(.top, 8)
                        
                        Text("Daily Forecast")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                        
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
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.secondarySystemBackground))
                        )
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 16)
                }
            } else {
                Spacer()
            }
        }
        .navigationTitle("Forecast")
        .navigationBarTitleDisplayMode(.inline)
        
        .task {
            await loadForecast()
        }
    }
    
    @MainActor
    private func loadForecast() async {
        isLoading = true
        errorMessage = nil
        forecast = nil
        
        do {
            forecast = try await getForecast(lat: city.latitude, lon: city.longitude)
        } catch {
            print("Forecast failed:", error)
            errorMessage = "Couldn’t load forecast right now"
        }
        
        isLoading = false
    }
}

// safe indexing helper
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
    ))
}
