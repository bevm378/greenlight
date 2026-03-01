//
//  ForecastView.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/19/26.
//

import SwiftUI

struct ForecastView: View {
    @Environment(\.dismiss) private var dismiss
    
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
    @State private var didLoadOnce = false
    
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
    
    private func prettyDate(_ apiDate: String) -> String {
        guard let d = Self.apiDateFormatter.date(from: apiDate) else { return apiDate }
        return Self.displayDateFormatter.string(from: d)
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
                    HStack { Spacer(); ProgressView().tint(.secondary); Spacer() }
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
                    Group {
                        let i = 0
                        let feelsHi = forecast.daily.apparent_temperature_max[safe: i]
                        let feelsLo = forecast.daily.apparent_temperature_min[safe: i]
                        let hi = forecast.daily.temperature_2m_max[safe: i]
                        let lo = forecast.daily.temperature_2m_min[safe: i]
                        let pop = forecast.daily.precipitation_probability_max?[safe: i]
                        let wind = forecast.daily.wind_speed_10m_max?[safe: i]
                        let windDir = forecast.daily.wind_direction_10m_dominant?[safe: i]
                        let gust = forecast.daily.wind_gusts_10m_max?[safe: i]
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
                            windDirDeg: windDir,
                            windGust: gust,
                            updatedText: nil
                        )
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
                        
                        Text("Daily Forecast")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .padding(.top)
                            .padding(.leading, 20)
                            .padding(.bottom, -4)
                        
                        forecastList(forecast)
                            .padding(.horizontal)
                    }
                    .opacity(didLoadOnce ? 1 : 0)
                    .animation(.easeInOut(duration: 0.25), value: didLoadOnce)
                }
            }
            .padding(.bottom, 16)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("\(city.name), \(city.admin1 ?? city.country)")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }

            if let onChangeCity {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Change city") { onChangeCity() }
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    toggleSavedCity(city)
                } label: {
                    Image(systemName: isSavedCity ? "pin.fill" : "pin")
                        .imageScale(.medium)
                }
                .tint(.accentColor)
            }
        }
        .task(id: city.id) {
            saveLastCity(city)
            await loadForecast()
        }
    }
    
    // MARK: - Networking
    
    @MainActor
    private func loadForecast() async {
        isLoading = true
        forecast = nil
        errorMessage = nil
        
        do {
            let newForecast = try await getForecast(lat: city.latitude, lon: city.longitude)
            withAnimation(.easeInOut(duration: 0.25)) {
                forecast = newForecast
                didLoadOnce = true
            }
        } catch {
            withAnimation(.easeInOut(duration: 0.2)) {
                forecast = nil
                errorMessage = "Couldn’t load forecast right now."
            }
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
    
    // MARK: - Verdict Card
    
    private func verdictCard(
        _ verdict: Verdict,
        high: Double?,
        low: Double?,
        popMax: Int?,
        windMph: Double?,
        windDirDeg: Double?,
        windGust: Double?,
        updatedText: String?
    ) -> some View {
        
        CardContainer(tint: verdict.level.color.opacity(0.6)) {
            VStack(alignment: .leading, spacing: 10) {
                
                // header
                HStack(spacing: 10) {
                    Circle()
                        .fill(verdict.level.color)
                        .frame(width: 12, height: 12)
                        .scaleEffect(verdict.level == .red ? 1.05 : 1.0)
                        .animation(.easeInOut(duration: 0.25), value: verdict.level)
                    Text(verdict.level.title)
                        .font(.title2.weight(.semibold))
                        .animation(.easeInOut(duration: 0.2), value: verdict.level)
                    Spacer()
                }
                
                // feels-like line
                Text(verdict.feelsLikeLine)
                    .foregroundStyle(.secondary)
                
                // metrics
                Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                    GridRow {
                        MetricChip("High", high.map { "\(Int($0.rounded()))°" } ?? "--",
                                   tint: chipTint(for: verdict.tempLevel))
                        MetricChip("Low", low.map { "\(Int($0.rounded()))°" } ?? "--",
                                   tint: chipTint(for: verdict.tempLevel))
                    }
                    GridRow {
                        MetricChip("Precip", popMax.map { "\($0)%" } ?? "--",
                                   tint: chipTint(for: verdict.rainLevel)) {
                            let p = Double(popMax ?? 0) / 100
                            PrecipArc(probability: Double(popMax ?? 0) / 100,
                                      color: Color.accentColor.opacity(0.25 + 0.75 * p),
                                      size: 30)
                        }
                        MetricChip("Wind", windMph.map { "\(Int($0.rounded())) mph" } ?? "--",
                                   tint: chipTint(for: verdict.windLevel)) {
                            let t = min(max((windMph ?? 0) / 30.0, 0), 1)
                            WindDial(mph: windMph ?? 0,
                                     color: Color.accentColor.opacity(0.25 + 0.75 * t),
                                     directionDeg: windDirDeg.map { $0 + 180 },
                                     maxMph: max(windGust ?? 30, 30),
                                     size: 30)
                        }
                    }
                }
                .padding(.top, 2)
                
                // why + recommendation lines
                VStack(alignment: .leading, spacing: 4) {
                    Text(verdict.whyLine)
                        .foregroundStyle(.secondary)
                    Text(verdict.recommendation)
                        .font(.headline)
                }
                
                // "updated" footer
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
        }
        .padding(.horizontal)
    }
    
    // MARK: - Forecast
    
    private func forecastList(_ forecast: ForecastResponse) -> some View {
        
        let dayCount = min(
            forecast.daily.time.count,
            forecast.daily.temperature_2m_max.count,
            forecast.daily.temperature_2m_min.count
        )
        
        return VStack(spacing: 0) {
            ForEach(0..<dayCount, id: \.self) { idx in
                NavigationLink {
                    
                    let verdict = makeVerdict(
                        feelsLikeHighF: forecast.daily.apparent_temperature_max[safe: idx],
                        feelsLikeLowF: forecast.daily.apparent_temperature_min[safe: idx],
                        actualHighF: forecast.daily.temperature_2m_max[safe: idx],
                        actualLowF: forecast.daily.temperature_2m_min[safe: idx],
                        popMax: forecast.daily.precipitation_probability_max?[safe: idx],
                        rainInches: forecast.daily.rain_sum?[safe: idx],
                        windMph: forecast.daily.wind_speed_10m_max?[safe: idx]
                    )
                    
                    DayDetailView(
                        cityName: "\(city.name), \(city.admin1 ?? city.country)",
                        dateText: prettyDate(forecast.daily.time[idx]),
                        hi: forecast.daily.temperature_2m_max[idx],
                        lo: forecast.daily.temperature_2m_min[idx],
                        pop: forecast.daily.precipitation_probability_max?[safe: idx],
                        wind: forecast.daily.wind_speed_10m_max?[safe: idx],
                        rain: forecast.daily.rain_sum?[safe: idx],
                        verdict: verdict
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
