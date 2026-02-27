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
    
    // MARK: - Persistent Storage
    
    @AppStorage("savedCity") private var savedCityData: String = ""
    @AppStorage("savedCities") private var savedCitiesData: String = "[]"
    
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
        let whyLine: String
        let recommendation: String
    }
    
    // MARK: - Derived State (Saved Cities)
    
    private var savedCities: [City] {
        guard let data = savedCitiesData.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([City].self, from: data)
        else { return [] }
        return decoded
    }

    private var isSavedCity: Bool {
        savedCities.contains(where: { $0.id == city.id })
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
                    let feelsHi = forecast.daily.apparent_temperature_max[safe: i]
                    let feelsLo = forecast.daily.apparent_temperature_min[safe: i]
                    let hi = forecast.daily.temperature_2m_max[safe: i]
                    let lo = forecast.daily.temperature_2m_min[safe: i]
                    let pop = forecast.daily.precipitation_probability_max?[safe: i]
                    let wind = forecast.daily.wind_speed_10m_max?[safe: i]
                    let rain = forecast.daily.rain_sum?[safe: i]
                    let todayVerdict = makeVerdict(
                        feelsLikeHighF: feelsHi,
                        feelsLikeLowF: feelsLo,
                        actualHighF: hi,
                        actualLowF: lo,
                        popMax: pop,
                        rainInches: rain,
                        windMph: wind
                    )

                    verdictCard(
                        todayVerdict,
                        high: hi,
                        low: lo,
                        popMax: pop,
                        windMph: wind,
                        updatedText: nil
                    )
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
            
            // left: change city
            if let onChangeCity {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Change city") { onChangeCity() }
                }
            }
            
            // right: save/unsave city (pin)
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if !isSavedCity { saveLastCity(city) }
                    toggleSavedCity(city)
                } label: {
                    Image(systemName: isSavedCity ? "pin.fill" : "pin")
                        .imageScale(.medium)
                }
                .tint(.accentColor)
                .accessibilityLabel(isSavedCity ? "Remove saved city" : "Save city")
            }
        }
        .task(id: city.id) { await loadForecast() }
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
    
    // MARK: - Saved Cities Actions
    
    private func toggleSavedCity(_ city: City) {
        var updated = savedCities
        
        if let idx = updated.firstIndex(where: { $0.id == city.id }) {
            updated.remove(at: idx)
        } else {
            updated.append(city)
        }
        
        // sort: population desc, then name
        updated.sort {
            let aPop = $0.population ?? -1
            let bPop = $1.population ?? -1
            if aPop != bPop { return aPop > bPop }
            return $0.name < $1.name
        }
        
        guard let data = try? JSONEncoder().encode(updated),
              let string = String(data: data, encoding: .utf8)
        else { return }
        savedCitiesData = string
    }

    private func saveLastCity(_ city: City) {
        guard let data = try? JSONEncoder().encode(city),
              let string = String(data: data, encoding: .utf8)
        else { return }
        savedCityData = string
    }
    
    // MARK: - Verdict Logic
    
    private func makeVerdict(
        feelsLikeHighF: Double?,
        feelsLikeLowF: Double?,
        actualHighF: Double?,
        actualLowF: Double?,
        popMax: Int?,
        rainInches: Double?,
        windMph: Double?
    ) -> Verdict {
        
        // temperature flags
        var tempLevel: VerdictLevel? = nil
        if let hi = actualHighF {
            if hi <= 25 { tempLevel = .red }
            else if hi <= 40 { tempLevel = .yellow }
        }
        if let lo = actualLowF, lo <= 25, tempLevel != .red { tempLevel = .yellow }
        
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
        
        // verdict card lines
        let feelsLikeLine: String = {
            if let hi = feelsLikeHighF, let lo = feelsLikeLowF { return "Feels like \(Int(lo.rounded())) – \(Int(hi.rounded()))°F" }
            if let hi = feelsLikeHighF { return "Feels like ~\(Int(hi.rounded()))°F" }
            return "Feels like --"
        }()
        
        let whyLine: String = {
            switch level {
            case .green:
                return "Clear conditions"
            case .yellow:
                if tempLevel == .yellow { return "Chilly" }
                if rainLevel == .yellow { return "Light rain" }
                if windLevel == .yellow { return "Breezy" }
                return "Mixed conditions"
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
                return "It's looking great outside!"
            case .yellow:
                if tempLevel == .yellow { return "It's OK outside, but add a warm layer" }
                if rainLevel == .yellow { return "It's OK outside, but bring a rain layer" }
                if windLevel == .yellow { return "It's OK outside, but stick to sheltered routes" }
                return "It's OK outside, but keep plans flexible"
            case .red:
                return "It's better to stay indoors"
            }
        }()
        
        return Verdict(
            level: level,
            feelsLikeLine: feelsLikeLine,
            whyLine: whyLine,
            recommendation: recommendation
        )
    }
    
    // MARK: - UI Helper
    private func prettyDate(_ apiDate: String) -> String {
        guard let d = Self.apiDateFormatter.date(from: apiDate) else { return apiDate }
        return Self.displayDateFormatter.string(from: d)
    }
    
    // MARK: - Verdict Card
    
    private func metricBlock(_ label: String, _ value: String) -> some View {
        HStack(spacing: 10) {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)
                    
            Text(value)
                .font(.body.monospacedDigit())
                .foregroundStyle(.primary)
                .frame(width: 60, alignment: .leading)
        }
    }
            
    private func verdictCard(
        _ verdict: Verdict,
        high: Double?,
        low: Double?,
        popMax: Int?,
        windMph: Double?,
        updatedText: String?
    ) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            HStack(spacing: 10) {
                Circle()
                    .fill(verdict.level.color)
                    .frame(width: 12, height: 12)

                Text(verdict.level.title)
                    .font(.title3.weight(.semibold))

                Spacer()
            }

            Text(verdict.feelsLikeLine)
                .foregroundStyle(.secondary)

            HStack {
                Spacer(minLength: 0)
            
                Grid(horizontalSpacing: 16, verticalSpacing: 6) {
                    GridRow {
                        metricBlock("High", high.map { "\(Int($0.rounded()))°" } ?? "--")
                        metricBlock("Precip", popMax.map { "\($0)%" } ?? "--")
                    }
                    
                    GridRow {
                        metricBlock("Low", low.map { "\(Int($0.rounded()))°" } ?? "--")
                        metricBlock("Wind", windMph.map { "\(Int($0.rounded())) mph" } ?? "--")
                    }
                }
                
                Spacer(minLength: 0)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(verdict.whyLine)
                    .foregroundStyle(.secondary)

                Text(verdict.recommendation)
                    .font(.headline)
            }

            if let updatedText {
                Divider().opacity(0.5)

                HStack(spacing: 6) {
                    Text("Updated")
                        .foregroundStyle(.secondary)
                    Text(updatedText)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(verdict.level.color.opacity(0.06))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color(.separator).opacity(0.18))
        )
        .padding(.horizontal)
    }
    
    private func forecastList(_ forecast: ForecastResponse) -> some View {
        
        let dayCount = min(
                forecast.daily.time.count,
                forecast.daily.temperature_2m_max.count,
                forecast.daily.temperature_2m_min.count
        )
        
        return VStack(spacing: 0) {
            ForEach(0..<dayCount, id: \.self) { idx in
                NavigationLink {
                    DayDetailView(
                        cityName: "\(city.name), \(city.admin1 ?? city.country)",
                        dateText: prettyDate(forecast.daily.time[idx]),
                        hi: forecast.daily.temperature_2m_max[idx],
                        lo: forecast.daily.temperature_2m_min[idx],
                        pop: forecast.daily.precipitation_probability_max?[safe: idx],
                        wind: forecast.daily.wind_speed_10m_max?[safe: idx],
                        rain: forecast.daily.rain_sum?[safe: idx]
                    )
                } label: {
                    forecastRow(
                        dateText: prettyDate(forecast.daily.time[idx]),
                        hi: forecast.daily.temperature_2m_max[idx],
                        lo: forecast.daily.temperature_2m_min[idx],
                        pop: forecast.daily.precipitation_probability_max?[safe: idx]
                    )
                }
                .buttonStyle(.plain)
                
                if idx != dayCount - 1 {
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
                HStack(spacing: 4) {
                    Image(systemName: "umbrella.fill")
                        .font(.caption)
                    Text(pop.map { "\($0)%" } ?? "--")
                        .font(.body.monospacedDigit())
                }
                .foregroundStyle(.secondary)
                .frame(width: 55, alignment: .leading)
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
