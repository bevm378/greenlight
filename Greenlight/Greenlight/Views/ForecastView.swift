//
//  ForecastView.swift
//  Greenlight
//
//  Created by Beverly Mutuku on 2/19/26.
//

import SwiftUI

struct ForecastView: View {
    let city: City

    @State private var isLoading = false
    @State private var forecast: ForecastResponse? = nil
    @State private var errorMessage: String? = nil
    
    private let apiDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .iso8601)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    private let displayDateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = "EEE, MMM d"
        return df
    }()

    private func prettyDate(_ apiDate: String) -> String {
        guard let d = apiDateFormatter.date(from: apiDate) else { return apiDate }
        return displayDateFormatter.string(from: d)
    }

    private func tempString(_ value: Double) -> String {
        String(format: "%2d°", Int(value.rounded()))
    }

    private func popString(_ value: Int) -> String {
        String(format: "%3d%%", value)
    }

    private func forecastRow(dateText: String, hi: Double, lo: Double, pop: Int?) -> some View {
        HStack(spacing: 12) {
            Text(dateText)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Text("H \(tempString(hi))")
                Text("L \(tempString(lo))")
                    .foregroundStyle(.secondary)
            }
            .monospacedDigit()
            .frame(width: 120, alignment: .trailing)

            HStack(spacing: 6) {
                Image(systemName: "umbrella.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 14)

                Text(pop.map(popString) ?? "  --")
            }
            .monospacedDigit()
            .foregroundStyle(.secondary)
            .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 6)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // ...
            if let forecast {
                List {
                    Section("Daily Forecast") {
                        ForEach(forecast.daily.time.indices, id: \.self) { i in
                            forecastRow(
                                dateText: prettyDate(forecast.daily.time[i]),
                                hi: forecast.daily.temperature_2m_max[i],
                                lo: forecast.daily.temperature_2m_min[i],
                                pop: forecast.daily.precipitation_probability_max?[safe: i]
                            )
                        }
                    }
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
            let fetched = try await getForecast(lat: city.latitude, lon: city.longitude)
            forecast = fetched
        } catch OpenMeteoAPIError.decodeFailed {
            print("Forecast decode failed for:", city.name)
            errorMessage = "Couldn’t load forecast right now"
        } catch {
            print("Forecast failed:", error)
            errorMessage = "Couldn’t load forecast right now"
        }
        
        isLoading = false
    }
}

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
